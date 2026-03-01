# TZ-2.8: Advanced — Payments, Stories, Business

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P2 (монетизація + розширені фічі, не критичні для MVP)
> **Sessions**: 2-3
> **Dependencies**: TZ-2.1 (core bot), TZ-2.7 (channel publishing)
> **Verdict**: BUILD 60% | ADAPT 30% | COPY 10%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.2 cat.G,H,J

---

## 1. Мета

Реалізувати розширені можливості Telegram Bot API 9.x:

1. **Payments (Stars)** — Telegram Stars invoices, paid media, subscriptions
2. **Stories** — публікація Stories від Business Account з interactive areas
3. **Business Features** — businessConnection, greeting/away messages, quick replies

Ці фічі перетворюють NanoClaw з інструменту комунікації на повноцінну
бізнес-платформу з монетизацією.

**Без цього ТЗ**: NanoClaw не може приймати оплату через Telegram,
не використовує Stories для маркетингу, не інтегрується з Telegram Business.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Telegram Stars Payments

```
PAYMENT FLOW:

Agent needs to charge user (paid content, consultation, etc.)
│
├── 1. Agent creates invoice via IPC:
│   /ipc/{group}/tasks/invoice-{id}.json
│   {
│     action: "create_invoice",
│     title: "AI Маркетинг-аудит",
│     description: "Повний аналіз вашого маркетингу за 30 днів",
│     price_stars: 100,           // price in Telegram Stars
│     payload: "audit-2026-03",   // internal tracking
│     photo_url: "https://...",   // optional cover image
│     need_name: false,
│     need_email: false,
│   }
│
├── 2. NanoClaw creates invoice:
│   ├── sendInvoice() → user sees payment card
│   │   OR
│   └── createInvoiceLink() → shareable payment URL
│
├── 3. User pays (Telegram handles Stars transfer)
│
├── 4. Telegram sends pre_checkout_query
│   ├── NanoClaw validates payload
│   └── answerPreCheckoutQuery(ok: true)
│
├── 5. Telegram sends successful_payment message
│   ├── Store transaction in payment_transactions
│   ├── Notify agent: "💰 Оплата отримана: 100⭐"
│   └── Trigger paid service (e.g., spawn audit skill)
│
└── 6. Refund if needed:
    refundStarPayment(user_id, telegram_payment_charge_id)
```

```typescript
interface InvoiceRequest {
  title: string;                       // max 32 chars
  description: string;                 // max 255 chars
  payload: string;                     // internal data (max 128 bytes)
  price_stars: number;                 // 1-10000 Stars
  photo_url?: string;
  photo_width?: number;
  photo_height?: number;
  need_name?: boolean;
  need_email?: boolean;
  need_phone_number?: boolean;
  is_flexible?: boolean;               // for dynamic pricing
}

class PaymentManager {
  private bot: Bot;

  // Send invoice directly in chat
  async sendInvoice(
    chatJid: string,
    invoice: InvoiceRequest,
    opts?: { message_thread_id?: number }
  ): Promise<number> {
    const msg = await this.bot.api.sendInvoice(
      chatJid.replace('tg:', ''),
      invoice.title,
      invoice.description,
      invoice.payload,
      'XTR',                           // Stars currency code
      [{ label: invoice.title, amount: invoice.price_stars }],
      {
        photo_url: invoice.photo_url,
        need_name: invoice.need_name,
        need_email: invoice.need_email,
        message_thread_id: opts?.message_thread_id,
      }
    );
    return msg.message_id;
  }

  // Create shareable invoice link
  async createInvoiceLink(invoice: InvoiceRequest): Promise<string> {
    return this.bot.api.createInvoiceLink(
      invoice.title,
      invoice.description,
      invoice.payload,
      'XTR',
      [{ label: invoice.title, amount: invoice.price_stars }],
    );
  }

  // Handle pre-checkout (validation before payment)
  async handlePreCheckout(query: PreCheckoutQuery): Promise<void> {
    // Validate payload, check availability
    const valid = await this.validatePayload(query.invoice_payload);
    await this.bot.api.answerPreCheckoutQuery(query.id, valid);
  }

  // Handle successful payment
  async handleSuccessfulPayment(payment: SuccessfulPayment, chatJid: string): Promise<void> {
    await this.storeTransaction({
      charge_id: payment.telegram_payment_charge_id,
      user_id: payment.from?.id?.toString(),
      chat_jid: chatJid,
      payload: payment.invoice_payload,
      amount_stars: payment.total_amount,
      currency: payment.currency,
      status: 'completed',
    });
    // Trigger post-payment action
  }

  // Refund payment
  async refundPayment(userId: number, chargeId: string): Promise<void> {
    await this.bot.api.refundStarPayment(userId, chargeId);
    await this.updateTransactionStatus(chargeId, 'refunded');
  }

  // Get Stars balance/transactions
  async getStarTransactions(offset?: number, limit?: number): Promise<StarTransactions> {
    return this.bot.api.getStarTransactions({ offset, limit });
  }
}
```

```sql
CREATE TABLE IF NOT EXISTS payment_transactions (
  charge_id TEXT PRIMARY KEY,          -- telegram_payment_charge_id
  user_id TEXT,
  chat_jid TEXT NOT NULL,
  payload TEXT NOT NULL,
  amount_stars INTEGER NOT NULL,
  currency TEXT DEFAULT 'XTR',
  status TEXT DEFAULT 'completed',     -- completed | refunded | failed
  created_at TEXT NOT NULL,
  refunded_at TEXT
);

CREATE INDEX idx_payments_user ON payment_transactions(user_id);
CREATE INDEX idx_payments_chat ON payment_transactions(chat_jid);
CREATE INDEX idx_payments_status ON payment_transactions(status);
```

#### B. Paid Media

```typescript
// Send content that requires Stars payment to access
// Bot API: sendPaidMedia

interface PaidMediaRequest {
  channel_jid: string;
  star_count: number;                  // price to unlock
  media: {
    type: 'photo' | 'video';
    source: string;                    // file_id or URL
  }[];
  caption?: string;
  show_caption_above_media?: boolean;
}

async function sendPaidMedia(request: PaidMediaRequest): Promise<number> {
  const msg = await bot.api.sendPaidMedia(
    request.channel_jid,
    request.star_count,
    request.media.map(m => ({
      type: `input_paid_media_${m.type}`,
      media: m.source,
    })),
    {
      caption: request.caption,
      show_caption_above_media: request.show_caption_above_media,
    }
  );
  return msg.message_id;
}
```

#### C. Stories Publishing

```typescript
// Stories API (Bot API 9.0+, Business Account only)

interface StoryContent {
  type: 'photo' | 'video';
  source: string;                      // file_id or URL
}

interface StoryArea {
  type: 'location' | 'link' | 'weather' | 'reaction' | 'unique_gift';
  position: {
    x_percentage: number;              // 0.0 - 100.0
    y_percentage: number;
    width_percentage: number;
    height_percentage: number;
    rotation_angle?: number;
  };
  // Type-specific data:
  url?: string;                        // for 'link' type
  latitude?: number;                   // for 'location' type
  longitude?: number;
}

class StoryPublisher {
  private bot: Bot;

  // Post a story
  async postStory(
    businessConnectionId: string,
    content: StoryContent,
    opts?: {
      caption?: string;
      areas?: StoryArea[];
      protect_content?: boolean;
      post_to_chat_page?: boolean;     // also show in channel chat
    }
  ): Promise<Story> {
    const media = content.type === 'photo'
      ? { type: 'input_story_content_photo', photo: content.source }
      : { type: 'input_story_content_video', video: content.source };

    return this.bot.api.postStory(businessConnectionId, media, opts);
  }

  // Edit story
  async editStory(
    businessConnectionId: string,
    storyId: number,
    content: StoryContent,
    opts?: { caption?: string; areas?: StoryArea[] }
  ): Promise<Story>;

  // Delete story
  async deleteStory(
    businessConnectionId: string,
    storyId: number
  ): Promise<void>;

  // Repost story (Bot API 9.3+)
  async repostStory(
    businessConnectionId: string,
    fromChatId: string,
    storyId: number
  ): Promise<Story>;
}
```

#### D. Business Connection Features

```typescript
// Telegram Business connection (bot manages business account)

interface BusinessConnectionHandler {
  // Handle new business connection
  onBusinessConnection(connection: BusinessConnection): Promise<void>;

  // Set greeting message (auto-reply for new DMs)
  setGreetingMessage(
    businessConnectionId: string,
    sticker?: InputSticker,            // greeting sticker
  ): Promise<void>;

  // Set away message (auto-reply when offline)
  setAwayMessage(
    businessConnectionId: string,
    text: string,
    schedule?: {
      type: 'always' | 'outside_hours' | 'custom';
      start_date?: number;
      end_date?: number;
    }
  ): Promise<void>;

  // Quick replies (template responses)
  getQuickReplies(): Promise<QuickReplyShortcut[]>;
}

// Business connection tracking
CREATE TABLE IF NOT EXISTS business_connections (
  connection_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,              -- business account owner
  bot_id TEXT NOT NULL,
  can_reply INTEGER DEFAULT 0,
  is_enabled INTEGER DEFAULT 1,
  date TEXT NOT NULL
);
```

#### E. Channel Direct Messages (9.2+)

```typescript
// Channel DMs: subscribers can DM the channel (through the bot)
// Each DM is a separate topic in the bot's chat with the channel

interface ChannelDmConfig {
  enabled: boolean;                    // enable DM feature on channel
  auto_reply_enabled: boolean;         // AI auto-reply to DMs
  auto_reply_delay_seconds: number;    // delay before auto-reply
  human_escalation: boolean;           // forward complex DMs to admin
}

// Handle incoming channel DM
async function handleChannelDm(
  ctx: Context,
  config: ChannelDmConfig
): Promise<void> {
  // Channel DMs come as messages with business_connection_id
  // and chat.type = 'private'
  if (config.auto_reply_enabled) {
    // Route to appropriate skill for response
    // Use standard agent pipeline
  }
  if (config.human_escalation) {
    // Forward to admin group topic
  }
}
```

### 2.2 Excluded (DEFER)

- **Fiat payment providers** (Stripe, etc.) — future, requires PCI compliance
- **Recurring subscriptions** (paid Stars subscriptions) — Phase 4
- **Gift Premium** (sendGift, getAvailableGifts) — low priority
- **Ad revenue withdrawal** — platform feature, not bot API
- **Suggested posts management** — Phase 4 (requires channel analytics first)
- **Mini Apps** — separate TZ (Phase 3, TZ-3.x)
- **Inline Mode** — separate TZ (Phase 4)
- **Checklists** (Bot API 9.1+) — low priority

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Stars invoice created and sent to user (sendInvoice)
- [ ] pre_checkout_query handled (validation)
- [ ] successful_payment processed and stored
- [ ] payment_transactions SQLite table
- [ ] Refund operation works (refundStarPayment)

### P1 — Full MVP

- [ ] Invoice link creation (createInvoiceLink)
- [ ] Paid media publishing (sendPaidMedia)
- [ ] Stars transaction history (getStarTransactions)
- [ ] Story publishing (postStory) for business accounts
- [ ] Story with interactive areas (link, location)
- [ ] Business connection handling
- [ ] business_connections SQLite table

### P2 — Extended

- [ ] Story reposting between accounts (9.3+)
- [ ] Greeting/away auto-messages for business
- [ ] Channel DM handling with auto-reply
- [ ] Quick replies templates
- [ ] Payment analytics (revenue per period)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/payments/payment-manager.ts` | CREATE | Invoice creation, checkout, refunds |
| `src/payments/paid-media.ts` | CREATE | Paid media publishing |
| `src/stories/story-publisher.ts` | CREATE | Stories CRUD |
| `src/business/connection-handler.ts` | CREATE | Business connection management |
| `src/business/channel-dm.ts` | CREATE | Channel DM handling |
| `src/channels/telegram.ts` | MODIFY | Payment + story + business handlers |
| `src/db.ts` | MODIFY | payment_transactions, business_connections tables |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 127-148 | Stories + Payments API map |
| `docs/architecture/phase-2-telegram.md` | 167-178 | Business features API map |
| `docs/architecture/phase-2-telegram.md` | 508-534 | channel-manager skill |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| grammY payments | grammY payments docs | COPY | Invoice creation patterns |
| Bot API 9.x methods | grammY API types | COPY | Stories, paid media types |
| Business bot | grammY business docs | ADAPT | Connection handling |

### Risks

1. **Stars API volatility** — Bot API 9.x is new, methods may change. Solution: abstract behind PaymentManager, easy to update.
2. **Business Account requirement** — Stories require business account. Solution: feature detection, clear error if not business.
3. **Payment compliance** — Stars payments have Telegram ToS requirements. Solution: document requirements, validate before enabling.
4. **DM volume** — Popular channels can get many DMs. Solution: rate limiting, auto-reply with queue for human escalation.
5. **Refund abuse** — Users may abuse refund. Solution: refund policy in configuration, limit refunds per user.

---

## 5. Testing

### Unit Tests

```typescript
describe('Payment Manager', () => {
  test('invoice created with correct Stars amount');
  test('pre_checkout validated and answered');
  test('successful payment stored in transactions');
  test('refund updates transaction status');
  test('invalid payload rejected at pre_checkout');
  test('Stars transaction history fetched');
});

describe('Paid Media', () => {
  test('paid media sent with star_count');
  test('multi-media paid content (album)');
});

describe('Story Publisher', () => {
  test('photo story posted');
  test('video story posted');
  test('story with link area');
  test('story edited');
  test('story deleted');
  test('story reposted between accounts');
});

describe('Business Connection', () => {
  test('connection event handled');
  test('connection stored in SQLite');
  test('greeting message set');
  test('away message set');
});
```

### Integration Tests

```typescript
describe('Advanced features E2E', () => {
  test('agent creates invoice → user pays → service triggered');
  test('agent publishes story → visible on business account');
  test('business DM received → auto-reply sent');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Stars payment flow works end-to-end
- [ ] Transactions stored and queryable
- [ ] Refund mechanism works
- [ ] Stories publishing works (if business account available)
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-2.1 (core bot), TZ-2.7 (channel publishing), TZ-2.3 (HITL for payment confirmations)_
