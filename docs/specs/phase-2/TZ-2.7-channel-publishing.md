# TZ-2.7: Channel Publishing

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P1 (маркетинговий канал = ключова дистрибуція)
> **Sessions**: 2-3
> **Dependencies**: TZ-2.1 (core bot), TZ-2.2 (adaptor, media groups)
> **Verdict**: ADAPT 60% | BUILD 25% | COPY 15%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.2 cat.F, §2.4-E

---

## 1. Мета

Реалізувати channel-manager — компонент для публікації контенту у Telegram-каналах:
форматовані пости, медіа-альбоми, розклад публікацій через NanoClaw scheduler,
трекінг реакцій та базова аналітика. Telegram канал = головний маркетинговий канал дистрибуції.

**Без цього ТЗ**: агент може генерувати контент, але не може публікувати його
у каналі. Маркетинговий ланцюжок обривається на кроці "дистрибуція".

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Channel Registration & Access

```
CHANNEL SETUP FLOW:

1. User adds bot as admin to Telegram channel
   (bot needs: post messages, edit messages, delete messages)

2. User registers channel in NanoClaw:
   /register-channel @channel_username
   OR
   /register-channel tg:-1001234567890

3. NanoClaw verifies:
   ├── Bot is admin of channel
   ├── Bot has required permissions
   └── Channel accessible

4. Store in SQLite:
   channels table (new):
   {
     channel_jid: "tg:-1001234567890",
     channel_username: "@my_channel",
     channel_title: "My Marketing Channel",
     owner_group: "main",          // which group controls this channel
     bot_permissions: {...},
     member_count: 1250,
     status: "active",
     created_at: "..."
   }
```

```sql
CREATE TABLE IF NOT EXISTS channels (
  channel_jid TEXT PRIMARY KEY,          -- tg:-100xxx (channel chat_id)
  channel_username TEXT,                 -- @username or null
  channel_title TEXT NOT NULL,
  owner_group TEXT NOT NULL,             -- registered_group folder that controls this
  bot_permissions TEXT,                  -- JSON: { can_post, can_edit, can_delete }
  member_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',          -- active | paused | disconnected
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (owner_group) REFERENCES registered_groups(folder)
);
```

#### B. Post Publishing

```typescript
interface ChannelPost {
  channel_jid: string;
  content: string;                       // Agent-generated markdown
  media?: MediaAttachment[];             // Photos, videos, documents
  parse_mode?: 'MarkdownV2' | 'HTML';
  disable_web_page_preview?: boolean;
  disable_notification?: boolean;        // silent post
  reply_markup?: InlineKeyboardMarkup;   // buttons (e.g., "Read more" link)
  scheduled_at?: string;                 // ISO 8601 for scheduled posting
}

interface MediaAttachment {
  type: 'photo' | 'video' | 'document';
  source: string;                        // file_id, URL, or local path
  caption?: string;
}

class ChannelPublisher {
  private bot: Bot;
  private adaptor: TelegramAdaptor;      // from TZ-2.2

  // Publish text post
  async publishText(post: ChannelPost): Promise<PublishResult> {
    const formatted = this.adaptor.convertToMarkdownV2(post.content);
    const chunked = this.adaptor.chunkMessage(formatted);

    if (chunked.overflow) {
      // Too long → send as document + summary
      return this.publishAsDocument(post);
    }

    const results: number[] = [];
    for (const chunk of chunked.chunks) {
      const msg = await this.bot.api.sendMessage(post.channel_jid, chunk, {
        parse_mode: post.parse_mode ?? 'MarkdownV2',
        disable_web_page_preview: post.disable_web_page_preview,
        disable_notification: post.disable_notification,
      });
      results.push(msg.message_id);
    }

    await this.logPublish(post, results);
    return { message_ids: results, channel: post.channel_jid };
  }

  // Publish media post (photo + caption, or album)
  async publishMedia(post: ChannelPost): Promise<PublishResult> {
    if (!post.media?.length) throw new Error('No media provided');

    if (post.media.length === 1) {
      // Single media
      const media = post.media[0];
      const method = media.type === 'photo' ? 'sendPhoto'
                   : media.type === 'video' ? 'sendVideo'
                   : 'sendDocument';
      const msg = await this.bot.api[method](post.channel_jid, media.source, {
        caption: post.content?.slice(0, 1024),  // Telegram caption limit
        parse_mode: post.parse_mode ?? 'MarkdownV2',
      });
      return { message_ids: [msg.message_id], channel: post.channel_jid };
    }

    // Album (2-10 items)
    return this.publishAlbum(post);
  }

  // Edit published post
  async editPost(
    channelJid: string,
    messageId: number,
    newContent: string
  ): Promise<void> {
    await this.bot.api.editMessageText(channelJid, messageId, {
      text: this.adaptor.convertToMarkdownV2(newContent),
      parse_mode: 'MarkdownV2',
    });
  }

  // Delete published post
  async deletePost(channelJid: string, messageId: number): Promise<void> {
    await this.bot.api.deleteMessage(channelJid, messageId);
    await this.logAction('delete', channelJid, messageId);
  }

  private async publishAlbum(post: ChannelPost): Promise<PublishResult>;
  private async publishAsDocument(post: ChannelPost): Promise<PublishResult>;
  private async logPublish(post: ChannelPost, messageIds: number[]): Promise<void>;
  private async logAction(action: string, channel: string, msgId: number): Promise<void>;
}

interface PublishResult {
  message_ids: number[];
  channel: string;
}
```

#### C. Scheduled Publishing

```
SCHEDULED PUBLISHING FLOW:

Agent generates post → sets scheduled_at
│
├── 1. Agent writes IPC task:
│   /ipc/{group}/tasks/publish-{id}.json
│   {
│     type: "schedule_task",
│     schedule_type: "once",
│     next_run: "2026-03-02T09:00:00Z",
│     data: {
│       action: "channel_publish",
│       channel_jid: "tg:-100xxx",
│       content: "...",
│       media: [...],
│     }
│   }
│
├── 2. NanoClaw scheduler stores task
│
├── 3. At scheduled time:
│   ├── Scheduler spawns container with publish task
│   ├── Agent calls ChannelPublisher.publishText/Media
│   └── Result logged
│
└── 4. Confirmation sent to owner group:
    "✅ Пост опубліковано в @channel (1250 підписників)"
```

```typescript
// Integration with existing NanoClaw task scheduler
interface ChannelPublishTaskData {
  action: 'channel_publish';
  channel_jid: string;
  content: string;
  media?: MediaAttachment[];
  parse_mode?: string;
  disable_notification?: boolean;
}

// Calendar view: upcoming scheduled posts
async function getScheduledPosts(
  channelJid: string,
  fromDate?: string,
  toDate?: string
): Promise<ScheduledTask[]> {
  // Query scheduled_tasks where data->action = 'channel_publish'
  // and data->channel_jid = channelJid
}
```

#### D. Reactions Tracking

```typescript
// Track reactions on channel posts for engagement analytics
// Bot API: message_reaction, message_reaction_count updates

interface ReactionEvent {
  channel_jid: string;
  message_id: number;
  reaction_type: string;          // emoji or custom emoji id
  count: number;
  timestamp: string;
}

// Handle reaction updates from Telegram
bot.on('message_reaction_count', (ctx) => {
  const chatId = `tg:${ctx.chat.id}`;
  const msgId = ctx.messageReactionCount.message_id;

  for (const reaction of ctx.messageReactionCount.reactions) {
    storeReaction({
      channel_jid: chatId,
      message_id: msgId,
      reaction_type: reaction.type.emoji || reaction.type.custom_emoji_id,
      count: reaction.total_count,
      timestamp: new Date().toISOString(),
    });
  }
});

// Reactions SQLite
CREATE TABLE IF NOT EXISTS channel_reactions (
  channel_jid TEXT NOT NULL,
  message_id INTEGER NOT NULL,
  reaction_type TEXT NOT NULL,
  count INTEGER DEFAULT 0,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (channel_jid, message_id, reaction_type)
);
```

#### E. Basic Channel Analytics

```typescript
interface ChannelStats {
  channel_jid: string;
  member_count: number;                  // from getChatMemberCount
  posts_last_7d: number;                 // from channel_posts log
  avg_reactions_per_post: number;        // from channel_reactions
  top_reactions: { emoji: string; total: number }[];
  scheduled_posts: number;               // upcoming scheduled
}

async function getChannelStats(channelJid: string): Promise<ChannelStats> {
  const memberCount = await bot.api.getChatMemberCount(channelJid);
  // ... aggregate from SQLite
}

// Published posts log
CREATE TABLE IF NOT EXISTS channel_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_jid TEXT NOT NULL,
  message_id INTEGER NOT NULL,
  content_preview TEXT,                  -- first 200 chars
  has_media INTEGER DEFAULT 0,
  published_at TEXT NOT NULL,
  scheduled INTEGER DEFAULT 0,          -- was it scheduled?
  FOREIGN KEY (channel_jid) REFERENCES channels(channel_jid)
);

CREATE INDEX idx_channel_posts_channel ON channel_posts(channel_jid);
CREATE INDEX idx_channel_posts_date ON channel_posts(published_at);
```

### 2.2 Excluded (DEFER)

- **Paid media (Stars content)** — TZ-2.8
- **Suggested posts management** — TZ-2.8
- **Channel DM (Direct Messages)** — TZ-2.8
- **Cross-posting between channels** — Phase 4
- **Post A/B testing** (publish variants, track engagement) — Phase 4
- **Content calendar UI** (Mini App) — Phase 3
- **Stories publishing** — TZ-2.8
- **Telegram MCP connector** — Phase 3 (MCP connectors)

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Channel registration: bot verifies admin access
- [ ] channels SQLite table created
- [ ] Publish text post to channel (MarkdownV2)
- [ ] Publish media post (photo with caption)
- [ ] channel_posts log records all publications
- [ ] Edit published post
- [ ] Delete published post

### P1 — Full MVP

- [ ] Scheduled publishing via NanoClaw scheduler
- [ ] Album publishing (2-10 media items)
- [ ] Reactions tracking (message_reaction_count)
- [ ] Basic channel stats: member count, posts, reactions
- [ ] Publish confirmation sent to owner group
- [ ] Silent posting mode (disable_notification)

### P2 — Extended

- [ ] Post templates (pre-formatted structures)
- [ ] Link preview control per post
- [ ] Post performance report (weekly digest)
- [ ] Bulk scheduling (multiple posts at once)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/channels/channel-publisher.ts` | CREATE | ChannelPublisher class |
| `src/channels/channel-registry.ts` | CREATE | Channel registration + verification |
| `src/channels/reaction-tracker.ts` | CREATE | Reactions event handling |
| `src/channels/channel-stats.ts` | CREATE | Analytics aggregation |
| `src/channels/telegram.ts` | MODIFY | reaction_count handler, channel commands |
| `src/db.ts` | MODIFY | channels, channel_posts, channel_reactions tables |
| `src/commands/register-channel.ts` | CREATE | /register-channel command |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 116-126 | Channel API capabilities |
| `docs/architecture/phase-2-telegram.md` | 500-534 | channel-manager skill |
| `src/task-scheduler.ts` | — | Existing scheduler for timed posts |
| `docs/specs/phase-2/TZ-2.2-*.md` | — | MarkdownV2 + chunking + media groups |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| Channel posting | social-media-mcp | ADAPT | Post formatting, scheduling |
| Marketing automation | marketing-mcp | ADAPT | Campaign scheduling patterns |
| Telegram MCP | chigwell/telegram-mcp | ADAPT | Channel operations as tools |
| Reaction tracking | grammY API | COPY | message_reaction_count handler |

### Risks

1. **Bot not admin** — Channel operations require bot as admin. Solution: verify on registration, clear error message.
2. **Rate limit on channel posts** — Telegram limits channel posting (30 msg/sec global). Solution: use TZ-2.2 rate limiter.
3. **Scheduled post drift** — NanoClaw scheduler granularity may cause ±60s drift. Solution: acceptable for marketing, document as known limitation.
4. **Large media uploads** — Telegram Bot API: 50MB limit (2GB with local API). Solution: validate file size before upload, suggest compression.

---

## 5. Testing

### Unit Tests

```typescript
describe('Channel Registration', () => {
  test('bot is admin → registration succeeds');
  test('bot not admin → registration fails with clear error');
  test('channel stored in SQLite');
  test('duplicate registration → update existing');
});

describe('Post Publishing', () => {
  test('text post published with MarkdownV2');
  test('long post chunked correctly');
  test('overflow → sent as document');
  test('media post: single photo with caption');
  test('album: 3 photos sent as media group');
  test('post logged in channel_posts');
});

describe('Scheduled Publishing', () => {
  test('scheduled post creates task in scheduler');
  test('task fires at scheduled time → post published');
  test('confirmation sent to owner group');
  test('getScheduledPosts returns upcoming posts');
});

describe('Reactions & Analytics', () => {
  test('reaction_count event stored correctly');
  test('channel stats aggregated from tables');
  test('member_count fetched from API');
});
```

### Integration Tests

```typescript
describe('Channel Publishing E2E', () => {
  test('register channel → publish post → track reactions → get stats');
  test('schedule post → wait → published at correct time');
  test('agent generates content → publishes to channel → confirmation');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Channel registration and verification works
- [ ] Text and media posts published correctly
- [ ] Posts logged for analytics
- [ ] Edit and delete operations work
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-2.1 (core bot), TZ-2.2 (adaptor, chunking, media), TZ-2.8 (paid media, stories)_
