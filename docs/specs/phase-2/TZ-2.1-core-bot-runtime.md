# TZ-2.1: Core Bot Runtime

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P0 (все в Phase 2 залежить від цього)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.2 (canonical store, 4-layer arch)
> **Verdict**: COPY 70% | ADAPT 20% | BUILD 10%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.1-2.3

---

## 1. Мета

Визначити core Telegram bot runtime: як NanoClaw підключається до Telegram,
обробляє вхідні оновлення (updates), керує командами, та забезпечує базову
двосторонню комунікацію. Це основа всіх TG-інтеграцій.

**Без цього ТЗ**: бот не підключений до Telegram, повідомлення не приходять,
відповіді не відправляються, HITL keyboards не працюють.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Bot Connection (grammY Framework)

**Existing (COPY):**
- `src/channels/telegram.ts` — TelegramChannel class (grammY Bot)
- Long polling via `bot.start()`, allowed_updates filter
- /chatid, /ping commands
- Text message handler with trigger pattern detection
- @mention translation → TRIGGER_PATTERN
- Chat metadata discovery (onChatMetadata callback)

**NanoClaw OS extensions (ADAPT):**
- Webhook support (alternative to long polling for production)
- setMyCommands with per-scope configuration:
  ```
  BotCommandScopeDefault:  /help, /status
  BotCommandScopeChat(main): /register-group, /list-groups, /export-session
  BotCommandScopeChat(group): /status, /tasks, /budget
  ```
- Allowed updates whitelist: message, callback_query, my_chat_member, chat_join_request
- Bot info caching: `bot.api.getMe()` at startup

#### B. Message Type Handlers

```typescript
// Current: only message:text
// Extension: handle all relevant message types

bot.on('message:text', handler);          // ✅ Existing
bot.on('message:voice', voiceHandler);    // NEW → TZ-2.4
bot.on('message:photo', photoHandler);    // NEW (with caption)
bot.on('message:document', docHandler);   // NEW (context files)
bot.on('message:video', videoHandler);    // NEW
bot.on('message:sticker', stickerHandler);// NEW (ignore or ack)
bot.on('callback_query:data', cbHandler); // NEW → TZ-2.3
bot.on('my_chat_member', memberHandler);  // NEW (bot join/leave)
bot.on('chat_join_request', joinHandler); // NEW → TZ-2.6
```

**Message normalization:**

```typescript
interface NormalizedMessage {
  id: string;
  chatJid: string;
  sender: string;
  senderName: string;
  content: string;               // text content (or transcription for voice)
  timestamp: string;
  type: 'text' | 'voice' | 'photo' | 'document' | 'video' | 'callback';
  threadId?: number;             // message_thread_id for forums
  replyToMessageId?: number;     // if replying to specific message
  mediaFileId?: string;          // Telegram file_id for media
  caption?: string;              // caption for media messages
}
```

#### C. Outbound Message API

```typescript
// Enhanced sendMessage with NanoClaw OS features
interface SendOptions {
  parse_mode?: 'MarkdownV2' | 'HTML';
  message_thread_id?: number;     // forum topic
  reply_markup?: InlineKeyboardMarkup | ReplyKeyboardMarkup;
  reply_to_message_id?: number;
  disable_web_page_preview?: boolean;
}

// Methods that telegram.ts must support:
class TelegramChannel {
  sendMessage(jid: string, text: string, opts?: SendOptions): Promise<void>;
  sendPhoto(jid: string, photo: InputFile, caption?: string, opts?: SendOptions): Promise<void>;
  sendDocument(jid: string, doc: InputFile, caption?: string, opts?: SendOptions): Promise<void>;
  sendVoice(jid: string, voice: InputFile, opts?: SendOptions): Promise<void>;
  editMessage(jid: string, messageId: number, text: string, opts?: SendOptions): Promise<void>;
  deleteMessage(jid: string, messageId: number): Promise<void>;
  setTyping(jid: string, isTyping: boolean): Promise<void>;
}
```

#### D. Group Model Integration

```
Telegram Group → NanoClaw Group mapping:

1. Bot added to group → my_chat_member event
2. Store metadata: tg:chatId, name, is_group=true
3. If not registered → log as available_group
4. If registered → start processing messages
5. Group type detection:
   - Private chat → DM commands only
   - Regular group → basic messaging
   - Supergroup → full features
   - Supergroup with Forums → thread routing (TZ-1.4)
```

#### E. Error Handling & Reconnection

```typescript
// Retry strategy for Telegram API
const RETRY_CONFIG = {
  maxRetries: 3,
  baseDelay: 1000,         // 1 second
  maxDelay: 30000,          // 30 seconds
  retryableErrors: [
    429,                     // Too Many Requests (rate limit)
    500, 502, 503, 504,     // Server errors
  ],
};

// Rate limit handling
// Telegram returns Retry-After header → wait and retry
// grammY auto-retry plugin handles this
```

### 2.2 Excluded (DEFER)

- **Webhook mode** setup and management — P2 (long polling sufficient for MVP)
- **Local Bot API Server** (self-hosted, 2GB files) — Phase 5
- **Inline mode** (answerInlineQuery) — Q4
- **Bot description/about** management — cosmetic, later
- **Multiple bots** (admin bot + channel bot split) — Phase 5

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] grammY Bot connects and receives all message types
- [ ] NormalizedMessage interface for all handlers
- [ ] setMyCommands per-scope registration
- [ ] sendMessage with parse_mode, message_thread_id, reply_markup
- [ ] my_chat_member handler (detect bot join/leave)
- [ ] Error handling with retry for rate limits

### P1 — Full MVP

- [ ] All 8 message type handlers registered (text/voice/photo/doc/video/sticker/callback/join)
- [ ] sendPhoto, sendDocument, sendVoice, editMessage, deleteMessage
- [ ] Group type detection (private/group/supergroup/forum)
- [ ] Bot info caching at startup

### P2 — Extended

- [ ] Webhook support as alternative to long polling
- [ ] Allowed updates filter configuration
- [ ] Connection health monitoring (heartbeat)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/channels/telegram.ts` | MODIFY | Add message handlers, sendPhoto/Doc/Voice |
| `src/types.ts` | MODIFY | Add NormalizedMessage interface |
| `src/channels/telegram-commands.ts` | CREATE | Command registration per-scope |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `src/channels/telegram.ts` | 1-100 | Existing TelegramChannel (grammY) |
| `src/types.ts` | 80-104 | Channel interface |
| `docs/architecture/phase-2-telegram.md` | 1-45 | Telegram dual role |
| `docs/architecture/phase-2-telegram.md` | 48-207 | Full Bot API map |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| grammY Bot setup | NanoClaw v1.1.3 `telegram.ts` | COPY | Base connection |
| @mention detection | NanoClaw v1.1.3 `telegram.ts` L74-92 | COPY | Trigger translation |
| Webhook + polling | claudegram | ADAPT | Production webhook setup |
| Error retry | grammY auto-retry plugin | COPY | Rate limit handling |
| Callback routing | Angusstone7 claude-code-telegram | ADAPT | callback_data parsing |

---

## 5. Testing

```typescript
describe('Core Bot Runtime', () => {
  test('text message normalized correctly');
  test('@mention translated to trigger pattern');
  test('unregistered group messages ignored');
  test('registered group messages delivered');
  test('commands registered per scope');
  test('rate limit retry works');
  test('forum message includes threadId');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] grammY Bot receives and processes all message types
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors
