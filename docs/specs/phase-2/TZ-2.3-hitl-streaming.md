# TZ-2.3: HITL & Streaming

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P0 (без стрімінгу — 10-60с тиші, без HITL — агент не може просити рішень)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.5 (HITL flow E), TZ-2.1 (core bot), TZ-2.2 (keyboards, adaptor)
> **Verdict**: BUILD 50% | ADAPT 30% | COPY 20%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.4-A, §2.4-C

---

## 1. Мета

Реалізувати два ключових UX-покращення для Telegram-каналу:

1. **Streaming відповідей** — замість тиші під час генерації Claude (10-60с),
   юзер бачить текст у реальному часі через `sendMessageDraft` (Bot API 9.3)
   або progressive sending (fallback).

2. **HITL Telegram integration** — з'єднати HITL-контракт з TZ-1.5
   (IPC hitl/ directory) з Telegram inline keyboards: callback routing,
   timeout з reminders, wizard flow (multi-step), colored buttons (9.3).

**Без цього ТЗ**: юзер чекає 60с без зворотного зв'язку, не може підтвердити
критичні дії (публікація, витрати), wizard flow неможливий.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Streaming Adapter

```
STREAMING PIPELINE:

Agent container (Claude SDK streaming)
│
├── stdout chunk 1: "Аналізую конкурентів..."
├── stdout chunk 2: "Знайшов 5 ключових гравців..."
├── stdout chunk 3: "Ось повний аналіз:\n\n1. ..."
│
└── container-runner → StreamingAdapter
                          │
                    ┌─────▼──────────────┐
                    │ MODE SELECTION:     │
                    │                     │
                    │ IF Bot API ≥ 9.3    │
                    │   AND client        │
                    │   supports drafts:  │
                    │   → DraftMode       │
                    │                     │
                    │ ELSE:               │
                    │   → ProgressiveMode │
                    └─────────────────────┘
```

**DraftMode (Bot API 9.3, primary):**

```typescript
class DraftStreamingAdapter {
  private draftMessageId: number | null = null;
  private accumulatedText: string = '';
  private chatId: string;
  private threadId?: number;

  async onChunk(chunk: string): Promise<void> {
    this.accumulatedText += chunk;

    if (!this.draftMessageId) {
      // First chunk → create draft
      const result = await bot.api.sendMessageDraft(this.chatId, {
        text: this.accumulatedText,
        message_thread_id: this.threadId,
      });
      this.draftMessageId = result.message_id;
    } else {
      // Subsequent chunks → update draft
      await bot.api.editMessageDraft(this.chatId, this.draftMessageId, {
        text: this.accumulatedText,
      });
    }
  }

  async finalize(): Promise<number> {
    // Convert draft to real message
    const msg = await bot.api.sendMessage(this.chatId, this.accumulatedText, {
      parse_mode: 'MarkdownV2',
      message_thread_id: this.threadId,
    });
    // Delete draft
    if (this.draftMessageId) {
      await bot.api.deleteMessage(this.chatId, this.draftMessageId);
    }
    return msg.message_id;
  }
}
```

**ProgressiveMode (fallback for older clients):**

```typescript
class ProgressiveStreamingAdapter {
  private sentMessageId: number | null = null;
  private accumulatedText: string = '';
  private lastEditAt: number = 0;
  private editIntervalMs: number = 2000;    // min 2s between edits
  private minChunkSize: number = 50;         // min chars before update

  async onChunk(chunk: string): Promise<void> {
    this.accumulatedText += chunk;

    const now = Date.now();
    const elapsed = now - this.lastEditAt;
    const enoughText = this.accumulatedText.length >= this.minChunkSize;

    if (!this.sentMessageId && enoughText) {
      // First meaningful chunk → send
      const msg = await bot.api.sendMessage(chatId, this.accumulatedText + ' ⏳');
      this.sentMessageId = msg.message_id;
      this.lastEditAt = now;
    } else if (this.sentMessageId && elapsed >= this.editIntervalMs && enoughText) {
      // Update existing message (throttled)
      await bot.api.editMessageText(chatId, this.sentMessageId, {
        text: this.accumulatedText + ' ⏳',
      });
      this.lastEditAt = now;
    }
  }

  async finalize(): Promise<number> {
    // Final edit with full text, no spinner
    if (this.sentMessageId) {
      await bot.api.editMessageText(chatId, this.sentMessageId, {
        text: convertToMarkdownV2(this.accumulatedText),
        parse_mode: 'MarkdownV2',
      });
      return this.sentMessageId;
    }
    // No message sent yet → send full
    const msg = await bot.api.sendMessage(chatId, this.accumulatedText);
    return msg.message_id;
  }
}
```

**Streaming Configuration:**

```typescript
interface StreamingConfig {
  enabled: boolean;                  // default: true
  mode: 'auto' | 'draft' | 'progressive' | 'disabled';
  progressive_interval_ms: number;   // default: 2000
  progressive_min_chars: number;     // default: 50
  draft_debounce_ms: number;         // default: 300
  max_draft_updates_per_sec: number; // default: 3
}
```

#### B. HITL Callback Router

```
CALLBACK FLOW (Telegram → IPC):

User clicks inline button
│
├── Telegram sends callback_query:
│   { id, data: "hitl:hitl-xxxx:approve", message, from }
│
├── telegram.ts → HitlCallbackRouter
│   ├── Parse callback_data → { prefix, request_id, action }
│   ├── Validate: request exists in active_hitl_requests
│   ├── Answer callback query (acknowledge click)
│   ├── Edit original message → remove keyboard, add ✅/❌ indicator
│   │
│   └── Write response to IPC:
│       /ipc/{group}/hitl-responses/{request_id}.json
│       { request_id, chosen: "approve", user_id, timestamp }
│
└── Agent container picks up response → continues execution
```

```typescript
// Callback data format (max 64 bytes in Telegram)
// Pattern: "hitl:{request_id}:{option_id}"
// Example: "hitl:h-a1b2c3:approve"

interface ParsedCallback {
  prefix: 'hitl' | 'wizard' | 'action';
  request_id: string;
  option_id: string;
}

function parseCallbackData(data: string): ParsedCallback | null {
  const parts = data.split(':');
  if (parts.length !== 3) return null;
  return {
    prefix: parts[0] as ParsedCallback['prefix'],
    request_id: parts[1],
    option_id: parts[2],
  };
}

class HitlCallbackRouter {
  // Active HITL requests (request_id → metadata)
  private activeRequests: Map<string, ActiveHitlRequest> = new Map();

  // Register HITL request from IPC
  registerRequest(request: HitlRequest, messageId: number): void;

  // Handle Telegram callback
  async handleCallback(callbackQuery: CallbackQuery): Promise<void>;

  // Check timeouts (called from polling loop)
  async checkTimeouts(): Promise<void>;
}

interface ActiveHitlRequest {
  request: HitlRequest;
  message_id: number;         // Telegram message with keyboard
  chat_jid: string;
  thread_id?: number;
  created_at: number;
  reminders_sent: number;     // 0, 1, 2
}
```

#### C. HITL Timeout & Reminders

```
TIMEOUT FLOW:

Request created (T=0)
│
├── T+15min → Reminder 1:
│   Edit message → add "⏰ 45 хв до автовибору: {default}"
│   Keep keyboard
│
├── T+30min → Reminder 2:
│   Edit message → add "⚠️ 30 хв до автовибору: {default}"
│   Keep keyboard
│
├── T+60min (timeout_minutes from request) → Auto-execute:
│   Remove keyboard
│   Edit message → "⏰ Автоматично обрано: {default_action}"
│   Write response to IPC with chosen=default_action
│
└── OR: User clicks before timeout → normal flow
```

```typescript
// Timeout SQLite tracking
// Extends registered hitl_requests

CREATE TABLE IF NOT EXISTS hitl_requests (
  request_id TEXT PRIMARY KEY,
  group_folder TEXT NOT NULL,
  chat_jid TEXT NOT NULL,
  message_id INTEGER NOT NULL,
  thread_id INTEGER,
  skill TEXT NOT NULL,
  question TEXT NOT NULL,
  options TEXT NOT NULL,            -- JSON array of HitlOption
  timeout_minutes INTEGER DEFAULT 60,
  default_action TEXT NOT NULL,
  reminders_sent INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',    -- pending | answered | timed_out | cancelled
  created_at TEXT NOT NULL,
  answered_at TEXT,
  FOREIGN KEY (group_folder) REFERENCES registered_groups(folder)
);
```

#### D. Wizard Flow (Multi-Step HITL)

```
WIZARD = послідовність HITL-кроків з back/next навігацією.
Агент визначає всі кроки заздалегідь.

IPC REQUEST (wizard type):
  /ipc/{group}/hitl/{request_id}.json
  {
    type: "hitl_wizard",
    request_id: "wiz-xxxx",
    skill: "marketing/content/copywriter",
    title: "Налаштування статті",
    steps: [
      {
        id: "audience",
        question: "Для якої аудиторії?",
        options: [
          { id: "beginners", label: "Початківці" },
          { id: "advanced", label: "Просунуті" },
          { id: "both", label: "Обидва рівні" }
        ]
      },
      {
        id: "length",
        question: "Яка довжина?",
        options: [
          { id: "short", label: "Коротка (500 слів)" },
          { id: "medium", label: "Середня (1500 слів)" },
          { id: "long", label: "Довга (3000 слів)" }
        ]
      },
      {
        id: "seo",
        question: "Включити SEO оптимізацію?",
        options: [
          { id: "yes", label: "✅ Так" },
          { id: "no", label: "❌ Ні" }
        ]
      }
    ],
    timeout_minutes: 30,
    default_actions: {
      "audience": "both",
      "length": "medium",
      "seo": "yes"
    }
  }
```

```typescript
interface WizardRequest {
  type: 'hitl_wizard';
  request_id: string;
  skill: string;
  title: string;
  steps: WizardStep[];
  timeout_minutes: number;
  default_actions: Record<string, string>;  // step_id → option_id
}

interface WizardStep {
  id: string;
  question: string;
  options: HitlOption[];
}

interface WizardState {
  request_id: string;
  current_step: number;           // 0-based index
  answers: Record<string, string>; // step_id → chosen option_id
  message_id: number;
}

// Wizard keyboard: options + navigation
function buildWizardKeyboard(step: WizardStep, stepIndex: number, totalSteps: number) {
  const rows = [];
  // Option buttons
  for (const opt of step.options) {
    rows.push([{
      text: opt.label,
      callback_data: `wizard:${requestId}:${opt.id}`,
    }]);
  }
  // Navigation row
  const nav = [];
  if (stepIndex > 0) {
    nav.push({ text: '⬅️ Назад', callback_data: `wizard:${requestId}:__back` });
  }
  nav.push({
    text: `${stepIndex + 1}/${totalSteps}`,
    callback_data: `wizard:${requestId}:__noop`,
  });
  rows.push(nav);
  return { inline_keyboard: rows };
}
```

**Wizard completion → IPC response:**

```json
{
  "request_id": "wiz-xxxx",
  "type": "wizard_response",
  "answers": {
    "audience": "advanced",
    "length": "medium",
    "seo": "yes"
  },
  "user_id": "12345",
  "timestamp": "2026-03-01T14:00:00Z"
}
```

#### E. Colored Buttons (Bot API 9.3)

```typescript
// Bot API 9.3 introduces button styles:
// - style: "default" (grey)
// - style: "constructive" (green)
// - style: "destructive" (red)

interface StyledInlineButton {
  text: string;
  callback_data: string;
  style?: 'default' | 'constructive' | 'destructive';
}

// Standard semantic mapping:
const BUTTON_STYLES = {
  approve: 'constructive',   // ✅ green
  reject: 'destructive',     // ❌ red
  edit: 'default',           // ✏️ grey
  cancel: 'destructive',     // red
  proceed: 'constructive',   // green
  back: 'default',           // grey
  next: 'default',           // grey
  skip: 'default',           // grey
};

// Feature detection: check if style is supported
function supportsButtonStyles(): boolean {
  // Check bot API version or use try/catch on first call
  return botApiVersion >= '9.3';
}
```

### 2.2 Excluded (DEFER)

- **HITL with media attachments** (approve photo/document) — Phase 4
- **HITL multi-user voting** (N users vote on decision) — Phase 4
- **Web App for complex HITL** (Mini App fallback for 10+ options) — Phase 3
- **Streaming for voice** (progressive audio TTS) — Phase 4
- **Edit history** for streaming messages (track all edits) — P2
- **sendMessageDraft with formatting** (MarkdownV2 in drafts) — depends on API support

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Streaming: ProgressiveMode works (edit existing message as chunks arrive)
- [ ] Streaming: fallback to `sendChatAction('typing')` if streaming disabled
- [ ] Streaming config: can disable per group (registered_groups.streaming_enabled)
- [ ] HITL callback: clicking button → response written to IPC hitl-responses/
- [ ] HITL callback: original message edited (keyboard removed, result shown)
- [ ] HITL timeout: after timeout_minutes → default_action executed
- [ ] Callback data format: `{prefix}:{request_id}:{option_id}` — parsed correctly

### P1 — Full MVP

- [ ] DraftMode streaming (sendMessageDraft / editMessageDraft) — Bot API 9.3
- [ ] Wizard flow: multi-step HITL with back navigation
- [ ] Wizard state persisted (SQLite) — survives bot restart
- [ ] HITL reminders: 2 reminders before timeout
- [ ] hitl_requests SQLite table with full state tracking
- [ ] Colored buttons: semantic mapping (approve=green, reject=red)

### P2 — Extended

- [ ] Streaming analytics: avg chunks per response, edit frequency
- [ ] HITL analytics: avg response time, timeout rate per skill
- [ ] Adaptive streaming interval (adjust based on message length)
- [ ] HITL escalation: if 2 timeouts in a row → notify admin

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/streaming/streaming-adapter.ts` | CREATE | StreamingAdapter interface + factory |
| `src/streaming/draft-mode.ts` | CREATE | DraftStreamingAdapter (Bot API 9.3) |
| `src/streaming/progressive-mode.ts` | CREATE | ProgressiveStreamingAdapter (fallback) |
| `src/hitl/callback-router.ts` | CREATE | Telegram callback → IPC response |
| `src/hitl/timeout-manager.ts` | CREATE | Timeout tracking + reminders |
| `src/hitl/wizard.ts` | CREATE | Multi-step wizard state machine |
| `src/channels/telegram.ts` | MODIFY | Add callback_query handler, streaming |
| `src/index.ts` | MODIFY | Integrate streaming into runAgent() pipeline |
| `src/db.ts` | MODIFY | Add hitl_requests table |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 320-368 | sendMessageDraft streaming spec |
| `docs/architecture/phase-2-telegram.md` | 416-457 | Inline Keyboards HITL levels |
| `docs/specs/phase-1/TZ-1.5-*.md` | 29-98 | HITL IPC contract, TypeScript interfaces |
| `src/index.ts` | runAgent() | Current output callback integration point |
| `src/ipc.ts` | processTaskIpc() | IPC directory polling pattern |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| ask-user HITL | linuz90/claude-code-telegram `ask-user.ts` | ADAPT | HITL request/response flow |
| Inline keyboards | Angusstone7/claude-code-telegram | ADAPT | Keyboard layout patterns |
| Streaming via edits | ductor `streaming.py` | ADAPT | Progressive message editing |
| Callback parsing | grammY bot.callbackQuery() | COPY | Callback event handling |
| Token bucket | RichardAtCT `rate_limiter.py` | ADAPT | Rate-limit streaming edits |

### Risks

1. **sendMessageDraft availability** — Bot API 9.3 may not be stable. Solution: ProgressiveMode as reliable fallback, auto-detect API version.
2. **Edit rate limit** — Too many edits trigger 429. Solution: throttle edits (min 2s interval), aggregate chunks.
3. **Callback data size** — 64 bytes max. Solution: use short request IDs (8 chars), compact format `hitl:h-a1b2:ok`.
4. **Wizard state loss on restart** — Solution: persist wizard state in SQLite, re-render on startup.
5. **Race condition: HITL expired but user clicks** — Solution: check status before writing response, answer with "⏰ Час вийшов, рішення прийнято автоматично".

---

## 5. Testing

### Unit Tests

```typescript
describe('Streaming - ProgressiveMode', () => {
  test('first chunk creates new message');
  test('subsequent chunks edit existing message');
  test('throttle: edits respect min interval');
  test('finalize removes spinner, applies MarkdownV2');
  test('empty response sends nothing');
});

describe('Streaming - DraftMode', () => {
  test('first chunk calls sendMessageDraft');
  test('subsequent chunks call editMessageDraft');
  test('finalize sends real message + deletes draft');
  test('fallback to Progressive if Draft API fails');
});

describe('HITL Callback Router', () => {
  test('valid callback parsed correctly');
  test('invalid callback returns error');
  test('callback writes response to IPC');
  test('original message edited after callback');
  test('duplicate callback ignored (idempotent)');
  test('expired request callback shows timeout message');
});

describe('HITL Timeout', () => {
  test('timeout fires after timeout_minutes');
  test('reminder 1 sent at 15 min');
  test('reminder 2 sent at 30 min');
  test('default action written to IPC on timeout');
  test('keyboard removed after timeout');
});

describe('Wizard Flow', () => {
  test('first step rendered with options');
  test('option selected → advance to next step');
  test('back button → return to previous step');
  test('last step → all answers collected → IPC response');
  test('wizard state survives bot restart');
  test('wizard timeout uses default_actions');
});
```

### Integration Tests

```typescript
describe('Streaming + HITL integration', () => {
  test('streamed response followed by HITL keyboard');
  test('HITL during streaming (agent pauses, sends keyboard)');
  test('wizard flow completes → agent container receives all answers');
  test('concurrent HITL requests from different groups isolated');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Progressive streaming tested with real Claude outputs (10s+ generation)
- [ ] HITL callback → IPC → agent resumption works end-to-end
- [ ] Timeout + reminders fire at correct intervals
- [ ] Wizard flow tested with 3-step sequence
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-1.5 (HITL flow contract), TZ-2.1 (core bot), TZ-2.2 (keyboards), TZ-2.4 (voice streaming)_
