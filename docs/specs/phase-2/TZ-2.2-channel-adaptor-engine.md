# TZ-2.2: Channel Adaptor Engine

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P0 (без адаптора виводу — кривий markdown, overflow повідомлень)
> **Sessions**: 2-3
> **Dependencies**: TZ-2.1 (core bot runtime)
> **Verdict**: ADAPT 70% | COPY 15% | BUILD 15%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.6

---

## 1. Мета

Побудувати Channel Adaptor Engine — компонент між скілами (platform-agnostic output)
і Telegram Bot API (platform-specific delivery). Відповідає за: MarkdownV2 конвертацію,
chunking (>4096 chars), rate limiting, media groups, та inline keyboard rendering.

**Без цього ТЗ**: великі відповіді обрізаються, markdown ламається, rate limit
блокує бота, HITL keyboards не рендеряться.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. MarkdownV2 Conversion

```typescript
// Agent output uses standard markdown.
// Telegram requires MarkdownV2 with specific escaping.

function convertToMarkdownV2(text: string): string {
  // 1. Escape special chars: _ * [ ] ( ) ~ ` > # + - = | { } . !
  // 2. Convert bold: **text** → *text*
  // 3. Convert italic: _text_ → _text_ (same but escaped context)
  // 4. Preserve code blocks: ```lang\ncode\n``` → ```lang\ncode\n```
  // 5. Preserve inline code: `code` → `code`
  // 6. Convert links: [text](url) → [text](url) (escape parens in url)
  // 7. Handle nested formatting edge cases
}

// Fallback: if MarkdownV2 parse fails → retry with HTML
// Fallback 2: if HTML fails → send as plain text
```

#### B. Chunking Strategy

```
IF output.length > 4096:
  1. Split at paragraph boundaries (\n\n)
  2. Each chunk ≤ 4000 chars (100 char buffer for formatting)
  3. Preserve code blocks (don't split mid-block)
  4. First chunk: content + "⬇️ Продовження нижче"
  5. Middle chunks: content
  6. Last chunk: content + inline keyboard (if HITL)
  7. Max 5 text chunks
  8. IF > 5 chunks → generate file → sendDocument + summary text

Delay between chunks: 100ms (avoid rate limit)
```

```typescript
interface ChunkResult {
  chunks: string[];
  overflow: boolean;      // true if > 5 chunks → file needed
  overflowContent?: string; // full content for file generation
}

function chunkMessage(text: string, maxLength: number = 4000): ChunkResult;
```

#### C. Rate Limiter

```typescript
// Telegram rate limits:
// - Private chats: 30 msg/sec globally
// - Groups: 20 msg/min per group
// - Global: 30 msg/sec total

class TelegramRateLimiter {
  private globalBucket: TokenBucket;    // 30 tokens/sec
  private groupBuckets: Map<string, TokenBucket>;  // 20 tokens/60sec per group
  
  async waitForSlot(chatJid: string): Promise<void>;
  
  // Handle 429 responses: extract Retry-After, wait, retry
  async handleRateLimit(retryAfter: number): Promise<void>;
}
```

#### D. Media Groups (Albums)

```typescript
// sendMediaGroup: up to 10 photos/videos in one album
interface MediaGroupItem {
  type: 'photo' | 'video' | 'document';
  media: string | InputFile;  // file_id or upload
  caption?: string;
}

async function sendMediaGroup(
  chatJid: string,
  items: MediaGroupItem[],
  opts?: { message_thread_id?: number }
): Promise<void>;
```

#### E. Reply Keyboard Management

```typescript
// Standard layouts from TZ-0.5 / architecture §2.4-C
const KEYBOARD_LAYOUTS = {
  approve_reject: [[
    { text: '✅ Так', callback_data: '{prefix}:approve' },
    { text: '❌ Ні', callback_data: '{prefix}:reject' },
  ]],
  approve_edit_reject: [[
    { text: '✅ Так', callback_data: '{prefix}:approve' },
    { text: '✏️ Правки', callback_data: '{prefix}:edit' },
    { text: '❌ Ні', callback_data: '{prefix}:reject' },
  ]],
  multi_option: (options: string[]) => [
    options.map(opt => ({ text: opt, callback_data: `{prefix}:${opt}` }))
  ],
  wizard_nav: [[
    { text: '⬅️ Назад', callback_data: '{prefix}:back' },
    { text: '➡️ Далі', callback_data: '{prefix}:next' },
  ]],
};
```

### 2.2 Excluded (DEFER)

- **HTML parse mode** as primary (MarkdownV2 is primary)
- **Custom emoji** on buttons (requires Premium bot)
- **Colored buttons** (style parameter, Bot API 9.3) — TZ-2.3
- **Forward/copy message** support — P2
- **Reaction management** — P2

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] MarkdownV2 conversion handles: bold, italic, code, links, lists
- [ ] Fallback chain: MarkdownV2 → HTML → plain text
- [ ] Chunking: messages >4096 chars split correctly at paragraph boundaries
- [ ] Code blocks preserved (not split mid-block)
- [ ] Rate limiter: per-group + global token bucket
- [ ] 429 response handled with Retry-After

### P1 — Full MVP

- [ ] Media group sending (album of 2-10 items)
- [ ] Overflow to file: >5 chunks → sendDocument
- [ ] Standard keyboard layouts (4 types)
- [ ] Callback data format: `{action}:{task_id}:{option}`

### P2 — Extended

- [ ] Forward/copy message support
- [ ] Reaction tracking on outbound messages

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/channel-adaptor/telegram-adaptor.ts` | CREATE | MarkdownV2 + chunking + rate limiting |
| `src/channel-adaptor/markdown-v2.ts` | CREATE | Markdown → MarkdownV2 converter |
| `src/channel-adaptor/rate-limiter.ts` | CREATE | Token bucket rate limiter |
| `src/channel-adaptor/keyboards.ts` | CREATE | Standard keyboard layouts |
| `src/channels/telegram.ts` | MODIFY | Use adaptor for all outbound |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| MarkdownV2 escaping | claudegram | ADAPT | Conversion rules |
| Chunking at paragraphs | claudegram | ADAPT | Split strategy |
| Token bucket rate limit | RichardAtCT rate_limiter.py | ADAPT | Port to TypeScript |
| Keyboard layouts | Angusstone7 keyboards | ADAPT | Standard HITL layouts |
| Streaming chunks | ductor streaming.py | ADAPT | Progressive delivery |

---

## 5. Testing

```typescript
describe('MarkdownV2 conversion', () => {
  test('bold text converted correctly');
  test('code blocks preserved');
  test('special chars escaped');
  test('nested formatting works');
  test('links with special chars in URL');
  test('fallback to HTML on parse error');
  test('fallback to plain text on HTML error');
});

describe('Chunking', () => {
  test('short message → single chunk');
  test('long message → multiple chunks');
  test('code block not split');
  test('overflow → file generation');
  test('chunk boundaries at paragraphs');
});

describe('Rate limiter', () => {
  test('global limit respected');
  test('per-group limit respected');
  test('429 response → wait and retry');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] MarkdownV2 converter passes all edge cases
- [ ] Chunking tested with real Claude outputs
- [ ] Rate limiter prevents 429 errors in production
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors
