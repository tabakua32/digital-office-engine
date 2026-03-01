# TZ-2.5: Forums & Group Management

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P1 (організація розмов; без цього — всі повідомлення в одному потоці)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.4 (forum hierarchy), TZ-2.1 (core bot)
> **Verdict**: BUILD 70% | ADAPT 20% | COPY 10%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.4-B, §2.2 cat.E

---

## 1. Мета

Реалізувати повну інтеграцію з Telegram Forum Topics — перетворити групу з
хаотичного потоку на структуровану проектну площадку з тематичними розділами.
Кожна тема = routing domain для скілів + окремий контекст розмови.

**Без цього ТЗ**: всі повідомлення в одному потоці, агент не може паралельно
обслуговувати маркетинг + аналітику + контент в одній групі. Масштабування неможливе.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Forum Topic Detection & Routing

```
INBOUND MESSAGE ENRICHMENT:

telegram.ts → message:text handler
│
├── Extract message_thread_id from ctx.message
│   (null = General topic or non-forum group)
│
├── Enrich NormalizedMessage:
│   {
│     ...existing fields,
│     thread_id: ctx.message.message_thread_id,
│     thread_name: resolveThreadName(chat_id, thread_id),
│     is_forum: ctx.chat.is_forum ?? false,
│   }
│
├── Thread-aware routing:
│   IF is_forum AND thread_id mapped in thread_routing table:
│     → Use thread's preferred skill/domain
│   ELSE:
│     → Standard trigger-based routing
│
└── Response delivery:
    sendMessage with message_thread_id = original thread_id
    (response goes to same topic)
```

```typescript
// Extended NormalizedMessage (from TZ-2.1)
interface NormalizedMessage {
  id: string;
  chat_jid: string;
  sender: string;
  sender_name: string;
  content: string;
  timestamp: string;
  is_from_me: boolean;
  // Forum extensions:
  thread_id?: number;           // message_thread_id from Telegram
  thread_name?: string;         // resolved topic name
  is_forum: boolean;            // chat.is_forum flag
}
```

#### B. Forum Topic Discovery

```
DISCOVERY FLOW (runs on group registration or /discover-topics):

1. bot.api.getForumTopicIcons(chatId)
   → Available icon colors/custom emojis

2. Iterate known message_thread_ids from recent messages
   OR use getChat() → check is_forum flag

3. For each discovered topic:
   Store in thread_routing table:
   {
     chat_jid: "tg:-1001234567890",
     thread_id: 42,
     thread_name: "✍️ Контент",
     mapped_domain: "marketing/content",
     mapped_skill: null,          // null = route by trigger
     is_active: true,
     discovered_at: "2026-03-01T..."
   }

4. Send summary to admin thread:
   "📋 Знайдено 6 тем:
    ✍️ Контент → marketing/content
    📊 Аналітика → data/analytics
    🔧 Система → meta/
    ..."
```

```sql
-- Thread routing table (from TZ-1.4, refined)
CREATE TABLE IF NOT EXISTS thread_routing (
  chat_jid TEXT NOT NULL,
  thread_id INTEGER NOT NULL,
  thread_name TEXT,
  mapped_domain TEXT,              -- marketing/content, data/analytics, etc.
  mapped_skill TEXT,               -- specific skill ID or null
  is_active INTEGER DEFAULT 1,
  is_system INTEGER DEFAULT 0,     -- true for NanoClaw system threads
  auto_respond INTEGER DEFAULT 1,  -- false = listen-only mode
  discovered_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (chat_jid, thread_id)
);

CREATE INDEX idx_thread_routing_chat ON thread_routing(chat_jid);
```

#### C. Topic CRUD Operations

```typescript
// Bot API Forum Topic methods (grammY wrappers)

class ForumManager {
  private bot: Bot;

  // Create new topic
  async createTopic(
    chatId: string,
    name: string,
    opts?: {
      icon_color?: number;           // 6 standard colors
      icon_custom_emoji_id?: string; // Premium custom emoji
    }
  ): Promise<{ message_thread_id: number }> {
    return this.bot.api.createForumTopic(chatId, name, opts);
  }

  // Edit topic name/icon
  async editTopic(
    chatId: string,
    threadId: number,
    opts: { name?: string; icon_custom_emoji_id?: string }
  ): Promise<void> {
    return this.bot.api.editForumTopic(chatId, threadId, opts);
  }

  // Close topic (archive, no new messages)
  async closeTopic(chatId: string, threadId: number): Promise<void> {
    return this.bot.api.closeForumTopic(chatId, threadId);
  }

  // Reopen closed topic
  async reopenTopic(chatId: string, threadId: number): Promise<void> {
    return this.bot.api.reopenForumTopic(chatId, threadId);
  }

  // Delete topic (permanent, admin only)
  async deleteTopic(chatId: string, threadId: number): Promise<void> {
    return this.bot.api.deleteForumTopic(chatId, threadId);
  }

  // Manage General topic visibility
  async hideGeneralTopic(chatId: string): Promise<void>;
  async unhideGeneralTopic(chatId: string): Promise<void>;
}
```

#### D. Standard Topic Templates

```typescript
// Pre-defined topic structures for different business types
const TOPIC_TEMPLATES = {
  // Marketing agency standard
  marketing_agency: [
    { name: '📌 General', domain: null, is_system: false },
    { name: '📊 Аналітика', domain: 'data/analytics' },
    { name: '✍️ Контент', domain: 'marketing/content' },
    { name: '🎯 Маркетинг', domain: 'marketing/distribution' },
    { name: '💰 Фінанси', domain: 'data/analytics' },
    { name: '🔧 Система', domain: 'meta/', is_system: true },
  ],

  // Solo entrepreneur
  solopreneur: [
    { name: '📌 General', domain: null },
    { name: '✍️ Контент', domain: 'marketing/content' },
    { name: '📊 Звіти', domain: 'data/analytics' },
    { name: '🔧 Система', domain: 'meta/', is_system: true },
  ],

  // Product team
  product_team: [
    { name: '📌 General', domain: null },
    { name: '🔬 Дослідження', domain: 'marketing/market-intelligence' },
    { name: '📝 Позиціонування', domain: 'marketing/positioning' },
    { name: '✍️ Контент', domain: 'marketing/content' },
    { name: '📈 Зростання', domain: 'marketing/scaling' },
    { name: '🔧 Система', domain: 'meta/', is_system: true },
  ],
};

// Apply template to existing forum group
async function applyTopicTemplate(
  chatId: string,
  template: keyof typeof TOPIC_TEMPLATES,
  forumManager: ForumManager
): Promise<void> {
  const topics = TOPIC_TEMPLATES[template];
  for (const topic of topics) {
    const result = await forumManager.createTopic(chatId, topic.name);
    // Store mapping in thread_routing
    await db.upsertThreadRouting({
      chat_jid: `tg:${chatId}`,
      thread_id: result.message_thread_id,
      thread_name: topic.name,
      mapped_domain: topic.domain ?? null,
      is_system: topic.is_system ?? false,
    });
  }
}
```

#### E. Pin Messages per Topic

```typescript
// Pin important messages within specific topics
// Use case: pin latest report in "📊 Аналітика" topic

async function pinInTopic(
  chatId: string,
  messageId: number,
  opts?: { disable_notification?: boolean }
): Promise<void> {
  // Telegram pins message in its topic automatically
  // (message_thread_id is part of the message)
  await bot.api.pinChatMessage(chatId, messageId, opts);
}

// Unpin
async function unpinInTopic(chatId: string, messageId: number): Promise<void> {
  await bot.api.unpinChatMessage(chatId, messageId);
}
```

#### F. Group Metadata Management

```typescript
// Extended group info for forum groups
interface ForumGroupInfo {
  chat_id: string;
  is_forum: boolean;
  topics: ThreadRoutingEntry[];
  member_count: number;
  admin_ids: string[];            // bot needs to know who can manage
  bot_is_admin: boolean;
  bot_can_manage_topics: boolean;
  default_template?: string;
}

// Check bot permissions for forum management
async function checkForumPermissions(chatId: string): Promise<{
  can_manage_topics: boolean;
  can_pin_messages: boolean;
  is_admin: boolean;
}> {
  const me = await bot.api.getChatMember(chatId, bot.botInfo.id);
  return {
    can_manage_topics: me.status === 'administrator' && me.can_manage_topics,
    can_pin_messages: me.status === 'administrator' && me.can_pin_messages,
    is_admin: me.status === 'administrator' || me.status === 'creator',
  };
}
```

### 2.2 Excluded (DEFER)

- **Auto-topic creation** (agent creates topics on demand) — Phase 4
- **Topic analytics** (messages per topic, activity heatmap) — Phase 4
- **Cross-group topic sync** (mirror topics across groups) — future
- **Private forum topics** (Bot API 9.3, topics in private chats) — P2
- **Topic-specific memory** (separate CLAUDE.md per topic) — Phase 4
- **Forum migration tool** (convert non-forum group to forum) — P2

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] message_thread_id extracted from Telegram messages
- [ ] Responses sent to same thread_id as incoming message
- [ ] thread_routing SQLite table created and populated
- [ ] Forum detection: is_forum flag read from chat metadata
- [ ] Non-forum groups work unchanged (backward compatibility)

### P1 — Full MVP

- [ ] Topic discovery: /discover-topics command populates thread_routing
- [ ] Topic CRUD: create, edit, close, reopen via ForumManager
- [ ] 3 topic templates: marketing_agency, solopreneur, product_team
- [ ] Thread-aware routing: topic domain → skill preference
- [ ] Pin messages in specific topics
- [ ] Bot permission check for forum management

### P2 — Extended

- [ ] Custom topic templates (user-defined)
- [ ] Topic archive/cleanup (close inactive topics)
- [ ] Private chat topics (Bot API 9.3)
- [ ] Topic rename propagation (update thread_routing on edit)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/forums/forum-manager.ts` | CREATE | Topic CRUD operations |
| `src/forums/topic-templates.ts` | CREATE | Standard topic templates |
| `src/forums/thread-router.ts` | CREATE | Thread → domain/skill mapping |
| `src/channels/telegram.ts` | MODIFY | Extract thread_id, send to thread |
| `src/db.ts` | MODIFY | thread_routing table, forum columns |
| `src/commands/discover-topics.ts` | CREATE | /discover-topics command |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 371-414 | Forums as project structure |
| `docs/architecture/phase-2-telegram.md` | 546-553 | forum-manager skill spec |
| `docs/specs/phase-1/TZ-1.4-*.md` | — | ThreadHierarchy schema, thread_routing table |
| `src/channels/telegram.ts` | 53-122 | Current message handling (no thread support) |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| Forum topic API | grammY API docs | COPY | createForumTopic, editForumTopic |
| Thread routing | NanoClaw thread_routing table | BUILD | New routing logic |
| Topic templates | — | BUILD | No reference, original design |
| telegram-mcp | chigwell/telegram-mcp | ADAPT | Forum operations as MCP tools |

### Risks

1. **Bot permission gaps** — Forum management requires `can_manage_topics` admin right. Solution: check permission on registration, warn if missing.
2. **Topic ID stability** — Topic IDs are permanent in Telegram. Solution: store once, update name only.
3. **General topic ID** — General topic has no message_thread_id (null). Solution: treat null thread_id as "General" topic.
4. **Race condition in discovery** — Two messages in new topic before discovery completes. Solution: on-the-fly mapping for unknown thread_ids.
5. **Template mismatch** — User's group already has topics that differ from templates. Solution: merge mode (add missing, don't delete existing).

---

## 5. Testing

### Unit Tests

```typescript
describe('Forum Topic Detection', () => {
  test('message_thread_id extracted from forum message');
  test('null thread_id treated as General topic');
  test('non-forum group: is_forum=false, no thread routing');
  test('response sent to same thread_id');
});

describe('Topic Discovery', () => {
  test('discovered topics stored in thread_routing');
  test('domain mapping applied from template');
  test('discovery summary sent to system thread');
});

describe('Topic CRUD', () => {
  test('create topic via ForumManager');
  test('edit topic name');
  test('close topic');
  test('reopen topic');
  test('delete topic removes from thread_routing');
});

describe('Topic Templates', () => {
  test('marketing_agency template creates 6 topics');
  test('solopreneur template creates 4 topics');
  test('template applied to empty forum group');
  test('template merged with existing topics (no duplicates)');
});

describe('Thread-Aware Routing', () => {
  test('message in "Контент" topic routes to marketing/content');
  test('message in unmapped topic uses trigger routing');
  test('system thread messages handled by meta/ skills');
});
```

### Integration Tests

```typescript
describe('Forums E2E', () => {
  test('register forum group → discover topics → route message → reply in thread');
  test('apply template → all topics created → routing works');
  test('non-forum group → upgrade to forum → topics appear');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] thread_id extracted and used for routing
- [ ] Responses go to correct forum topic
- [ ] Non-forum groups unaffected
- [ ] Topic CRUD operations tested
- [ ] At least 1 template applied successfully
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-1.4 (forum hierarchy spec), TZ-2.1 (core bot), TZ-2.6 (moderation in topics)_
