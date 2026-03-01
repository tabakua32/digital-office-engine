# TZ-2.6: Moderation & Security

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P1 (без модерації — спам і зловживання в групах)
> **Sessions**: 1-2
> **Dependencies**: TZ-2.1 (core bot), TZ-2.5 (group management)
> **Verdict**: ADAPT 60% | BUILD 25% | COPY 15%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.2 cat.D,L

---

## 1. Мета

Побудувати модуль модерації для Telegram груп NanoClaw: автоматична анти-спам
фільтрація, управління учасниками (ban/restrict), модерація заявок на вступ,
welcome messages для нових учасників, та rate-limiting на рівні юзера.

**Без цього ТЗ**: публічні групи засипаються спамом, бот не може захистити
робочі простори, нові учасники не отримують інструкцій.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Anti-Spam Engine

```
SPAM DETECTION PIPELINE:

Incoming message
│
├── 1. Rate check (per user):
│   IF user sent > N messages in M seconds → flag
│   Default: 10 msg / 60 sec → restrict for 5 min
│
├── 2. Content check:
│   ├── Known spam patterns (regex list):
│   │   - Crypto scams: /earn.*\$.*day/i, /bitcoin.*guaranteed/i
│   │   - Telegram spam: /t\.me\/joinchat/i (unauthorized invite links)
│   │   - Adult content: predefined blacklist
│   │   └── Custom patterns (per-group configurable)
│   │
│   ├── New member + first message = link → high suspicion
│   │
│   └── Score: 0-100 (>70 = auto-action)
│
├── 3. Action (based on score + config):
│   ├── score 0-30:  pass (normal message)
│   ├── score 30-70: flag for admin review (HITL)
│   ├── score 70-90: restrict user + delete message
│   └── score 90+:   ban user + delete message
│
└── 4. Logging:
    Store in moderation_log table for analytics
```

```typescript
interface SpamCheckResult {
  score: number;                    // 0-100
  reasons: string[];                // ["rate_limit", "spam_pattern:crypto"]
  action: 'pass' | 'flag' | 'restrict' | 'ban';
}

interface AntiSpamConfig {
  enabled: boolean;                 // default: true
  rate_limit: {
    messages: number;               // default: 10
    window_seconds: number;         // default: 60
    restrict_minutes: number;       // default: 5
  };
  patterns: string[];               // additional regex patterns
  auto_ban_score: number;           // default: 90
  auto_restrict_score: number;      // default: 70
  flag_score: number;               // default: 30
  new_member_grace_period_hours: number; // default: 24
  whitelist_user_ids: string[];     // never restrict these users
}

class AntiSpamEngine {
  private config: AntiSpamConfig;
  private userMessageCounts: Map<string, { count: number; windowStart: number }>;

  async checkMessage(message: NormalizedMessage): Promise<SpamCheckResult>;
  private checkRateLimit(userId: string): number;
  private checkContentPatterns(text: string): { score: number; patterns: string[] };
  private checkNewMemberBehavior(userId: string, chatJid: string): number;
}
```

#### B. Member Management Actions

```typescript
class MemberManager {
  private bot: Bot;

  // Ban user (remove from group permanently)
  async banUser(
    chatId: string,
    userId: number,
    opts?: {
      until_date?: number;            // Unix timestamp, 0 = permanent
      revoke_messages?: boolean;       // delete all user's messages
    }
  ): Promise<void> {
    await this.bot.api.banChatMember(chatId, userId, opts);
    await this.logAction('ban', chatId, userId, opts);
  }

  // Restrict user (limit permissions)
  async restrictUser(
    chatId: string,
    userId: number,
    permissions: ChatPermissions,
    until_date?: number
  ): Promise<void> {
    await this.bot.api.restrictChatMember(chatId, userId, {
      permissions,
      until_date,
    });
    await this.logAction('restrict', chatId, userId, { permissions, until_date });
  }

  // Unban/unrestrict user
  async unbanUser(chatId: string, userId: number): Promise<void> {
    await this.bot.api.unbanChatMember(chatId, userId, { only_if_banned: true });
    await this.logAction('unban', chatId, userId);
  }

  // Mute user (restrict send_messages only)
  async muteUser(chatId: string, userId: number, minutes: number): Promise<void> {
    const until = Math.floor(Date.now() / 1000) + minutes * 60;
    await this.restrictUser(chatId, userId, {
      can_send_messages: false,
      can_send_media_messages: false,
      can_send_other_messages: false,
    }, until);
  }

  // Delete specific message
  async deleteMessage(chatId: string, messageId: number): Promise<void> {
    await this.bot.api.deleteMessage(chatId, messageId);
    await this.logAction('delete_message', chatId, null, { messageId });
  }

  // Get user info (for moderation context)
  async getUserInfo(chatId: string, userId: number): Promise<ChatMember>;

  private async logAction(
    action: string,
    chatId: string,
    userId: number | null,
    details?: Record<string, unknown>
  ): Promise<void>;
}
```

#### C. Join Request Moderation

```
JOIN REQUEST FLOW:

Group has "approve new members" enabled
│
├── User requests to join → chat_join_request update
│
├── NanoClaw evaluates:
│   ├── Auto-approve rules:
│   │   - User has Telegram Premium → approve (configurable)
│   │   - User account age > 30 days → approve
│   │   - User is already in another NanoClaw group → approve
│   │
│   ├── Auto-decline rules:
│   │   - Account age < 1 day → decline
│   │   - Username matches spam pattern → decline
│   │
│   └── HITL (manual review):
│       → Send to admin/system topic:
│         "📋 Заявка на вступ:
│          👤 Name: {name}
│          📅 Account: {age} days old
│          [✅ Прийняти] [❌ Відхилити]"
│
├── Admin clicks → approveChatJoinRequest / declineChatJoinRequest
│
└── Log decision in moderation_log
```

```typescript
interface JoinRequestConfig {
  auto_approve: boolean;             // default: false (manual review)
  auto_approve_rules: {
    premium_users: boolean;          // default: true
    min_account_age_days: number;    // default: 7
    known_users: boolean;            // in other NanoClaw groups
  };
  auto_decline_rules: {
    min_account_age_days: number;    // default: 1
    spam_username_patterns: string[];
  };
}
```

#### D. Welcome Messages

```typescript
interface WelcomeConfig {
  enabled: boolean;                  // default: true
  message_template: string;          // supports {name}, {group_name} placeholders
  // Default: "👋 Вітаємо, {name}! Це робочий простір {group_name}."
  send_in_thread?: number;           // specific thread for welcomes (null = General)
  delete_after_minutes?: number;     // auto-delete welcome after N min (null = keep)
  pin_rules_message?: boolean;       // pin rules message for new members
}

// Welcome message handler
async function handleNewMember(
  ctx: Context,
  config: WelcomeConfig
): Promise<void> {
  if (!config.enabled) return;

  const name = ctx.from?.first_name || 'користувач';
  const groupName = (ctx.chat as any).title || 'група';

  const text = config.message_template
    .replace('{name}', name)
    .replace('{group_name}', groupName);

  const msg = await bot.api.sendMessage(ctx.chat.id, text, {
    message_thread_id: config.send_in_thread,
  });

  if (config.delete_after_minutes) {
    setTimeout(async () => {
      await bot.api.deleteMessage(ctx.chat.id, msg.message_id).catch(() => {});
    }, config.delete_after_minutes * 60 * 1000);
  }
}
```

#### E. Moderation Log (SQLite)

```sql
CREATE TABLE IF NOT EXISTS moderation_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chat_jid TEXT NOT NULL,
  user_id TEXT,
  action TEXT NOT NULL,              -- ban | restrict | mute | unban | delete | approve | decline | spam_detect
  reason TEXT,
  details TEXT,                      -- JSON: additional context
  moderator TEXT,                    -- 'auto' | user_id who clicked button
  created_at TEXT NOT NULL
);

CREATE INDEX idx_modlog_chat ON moderation_log(chat_jid);
CREATE INDEX idx_modlog_user ON moderation_log(user_id);
CREATE INDEX idx_modlog_action ON moderation_log(action);
```

#### F. Per-Group Moderation Config

```sql
-- Extend registered_groups
ALTER TABLE registered_groups ADD COLUMN antispam_enabled INTEGER DEFAULT 1;
ALTER TABLE registered_groups ADD COLUMN antispam_config TEXT;  -- JSON AntiSpamConfig
ALTER TABLE registered_groups ADD COLUMN welcome_enabled INTEGER DEFAULT 1;
ALTER TABLE registered_groups ADD COLUMN welcome_config TEXT;   -- JSON WelcomeConfig
ALTER TABLE registered_groups ADD COLUMN join_moderation TEXT DEFAULT 'manual';
-- 'auto' | 'manual' | 'disabled'
```

### 2.2 Excluded (DEFER)

- **AI-based spam detection** (Claude evaluates suspicious messages) — Phase 4
- **User reputation system** (trust score based on history) — Phase 4
- **Invite link analytics** (track which links bring spam) — P2
- **Aggressive anti-spam mode** (Telegram native feature toggle) — P2
- **Third-party verification** (Bot API 8.2+) — future
- **User ratings** (Bot API 9.3+) — future
- **Cross-group ban sync** (ban in one group → ban in all) — Phase 4

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Anti-spam: rate limiting per user works (10 msg/60s → restrict)
- [ ] Anti-spam: pattern matching detects common spam
- [ ] Ban/restrict/mute user functions work
- [ ] Delete message works
- [ ] moderation_log table stores all actions
- [ ] Anti-spam configurable per group (enable/disable)

### P1 — Full MVP

- [ ] Join request moderation with auto-approve/decline rules
- [ ] HITL for manual join request review
- [ ] Welcome messages for new members
- [ ] Welcome message templates with placeholders
- [ ] Per-group moderation config in SQLite
- [ ] Whitelist: admin users never restricted

### P2 — Extended

- [ ] Spam score analytics (top spam patterns, false positives)
- [ ] Custom spam patterns per group
- [ ] Auto-delete welcome messages after timeout
- [ ] Moderation stats command: /mod-stats

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/moderation/anti-spam.ts` | CREATE | AntiSpamEngine class |
| `src/moderation/member-manager.ts` | CREATE | Ban/restrict/mute actions |
| `src/moderation/join-handler.ts` | CREATE | Join request processing |
| `src/moderation/welcome.ts` | CREATE | Welcome message handler |
| `src/channels/telegram.ts` | MODIFY | Add join_request handler, spam check |
| `src/db.ts` | MODIFY | moderation_log table, group config columns |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 94-103 | Groups & Supergroups API |
| `docs/architecture/phase-2-telegram.md` | 187-197 | Moderation & Admin API |
| `docs/architecture/phase-2-telegram.md` | 536-544 | group-moderator skill spec |
| `src/channels/telegram.ts` | — | Current handler pattern |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| Input validation | RichardAtCT security/validators.py | ADAPT | Spam pattern structure |
| Chat management | telegram-mcp (chigwell) | ADAPT | Ban/restrict wrappers |
| Rate limiting | RichardAtCT rate_limiter.py | ADAPT | Per-user rate limiter |
| Join moderation | grammY docs | COPY | chat_join_request handling |

### Risks

1. **False positives** — Aggressive spam filter blocks legitimate users. Solution: start conservative, tune based on moderation_log.
2. **Bot permission insufficient** — Bot needs admin rights for ban/restrict. Solution: check permissions on group registration, warn if missing.
3. **Race condition in rate limit** — Multiple messages arrive simultaneously. Solution: atomic counter with Map, not SQLite for hot path.
4. **Welcome message spam** — Many users join simultaneously → flood. Solution: batch welcome messages (1 message per 10s window).

---

## 5. Testing

### Unit Tests

```typescript
describe('Anti-Spam Engine', () => {
  test('rate limit: 10 messages in 60s → restrict');
  test('rate limit: normal pace → pass');
  test('pattern match: crypto spam detected');
  test('pattern match: invite link detected');
  test('new member + link = high score');
  test('whitelisted user never restricted');
  test('score thresholds: pass/flag/restrict/ban');
});

describe('Member Manager', () => {
  test('ban user calls banChatMember');
  test('mute user restricts for N minutes');
  test('unban user calls unbanChatMember');
  test('all actions logged in moderation_log');
});

describe('Join Request Moderation', () => {
  test('auto-approve: premium user approved');
  test('auto-decline: new account declined');
  test('manual review: HITL keyboard sent to admin');
  test('admin approves → user added');
  test('admin declines → user rejected');
});

describe('Welcome Messages', () => {
  test('new member → welcome sent');
  test('template placeholders replaced');
  test('welcome disabled → no message');
  test('auto-delete after timeout');
});
```

### Integration Tests

```typescript
describe('Moderation E2E', () => {
  test('spam message → detect → restrict user → delete message → log');
  test('join request → auto-rules → approved/declined');
  test('new member → welcome → message in correct thread');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Anti-spam detects and restricts obvious spam
- [ ] Ban/restrict/mute operations work via Telegram API
- [ ] All moderation actions logged
- [ ] Per-group configuration works
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-2.1 (core bot), TZ-2.5 (group management), TZ-2.3 (HITL for moderation decisions)_
