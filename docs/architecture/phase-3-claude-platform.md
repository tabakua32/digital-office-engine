# NanoClaw OS — Генеральний Архітектурний План

**Фаза 3: CLAUDE PLATFORM LAYER & RUNTIMES**

**Version**: 1.0
**Date**: 2026-02-28
**Status**: Кінцевий дизайн
**Залежності**: Фаза 1 (топологія), Фаза 2/2.5 (Telegram), Фаза 4 (flows)

---

## 3.1 SCOPE ФАЗИ 3

```
Фаза 2 відповіла: "Як NanoClaw використовує КОЖНУ можливість Telegram?"
Фаза 3 відповідає: "Як NanoClaw використовує КОЖНУ можливість Claude API?"

Ця фаза покриває:
├── Claude API повна карта (Messages, Batch, Caching, Compaction, Tools)
├── Модельний матрикс per function type
├── Extended Thinking стратегії
├── MCP + Tool Search + Context Budget
├── Container ↔ Claude SDK інтеграція
├── Session management per runtime
├── Cost optimization framework
├── Rate limits, error handling, retry
└── Cross-references до Фази 4 (де flows використовують API)
```

---

## 3.2 CLAUDE API — ПОВНА КАРТА

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  CLAUDE API v2026 — CAPABILITIES MAP                               ║
║  (аналог Фази 2 для Bot API)                                      ║
║                                                                    ║
║  A. MESSAGES API (основний)                                        ║
║  ─────────────────────────                                         ║
║  POST /v1/messages                                                  ║
║  ├── model: вибір моделі                                           ║
║  ├── system: system prompt (Layer 1+2+3)                            ║
║  ├── messages: conversation history                                 ║
║  ├── max_tokens: ліміт output (64K Sonnet/Haiku, 128K Opus)       ║
║  ├── temperature: 0.0-1.0                                          ║
║  ├── tools: масив tool definitions                                 ║
║  ├── tool_choice: auto/any/specific/none                           ║
║  ├── metadata.user_id: per-user tracking                           ║
║  ├── stop_sequences: custom stop tokens                             ║
║  ├── stream: true/false (SSE streaming)                            ║
║  └── context_management: compaction strategy (beta)                ║
║                                                                    ║
║  CONTEXT WINDOWS (Feb 2026):                                        ║
║  ├── Standard: 200K tokens (усі моделі)                            ║
║  ├── Extended: 1M tokens (beta, Opus 4.6 + Sonnet 4.6, Tier 4)    ║
║  │   ⚠️ >200K input → DOUBLE pricing ($6/$22.50 Sonnet)            ║
║  ├── Output limits: Opus 4.6 = 128K, Sonnet 4.6 = 64K, Haiku = 64K║
║  │   ⚠️ 128K output header (3.7 Sonnet) NOT available on 4.x       ║
║  └── NanoClaw: Standard 200K sufficient, 1M = Future escape hatch ║
║                                                                    ║
║  NanoClaw використання:                                             ║
║  ├── КОЖЕН agent request → POST /v1/messages                       ║
║  ├── system = 3-layer prompt (Foundation + Context + Skill)        ║
║  ├── tools = IPC tools + MCP tools + skill-specific tools          ║
║  ├── stream = true (для sendMessageDraft → Telegram)               ║
║  ├── metadata.user_id = company_id (для rate limit isolation)      ║
║  └── temperature: by task type (див. §3.3 Model Matrix)            ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  B. EXTENDED THINKING (Adaptive Thinking API, Feb 2026)            ║
║  ─────────────────────────────────────────────────────              ║
║                                                                    ║
║  ⚠️ BREAKING CHANGE: budget_tokens DEPRECATED на 4.6 моделях.     ║
║  Замінено на Adaptive Thinking з параметром `effort`.               ║
║                                                                    ║
║  НОВА ПАРАДИГМА (Opus 4.6 + Sonnet 4.6):                          ║
║  ├── thinking.type: "enabled" (automatic)                          ║
║  ├── thinking.effort: low | medium | high (default) | max          ║
║  │   → Claude ДИНАМІЧНО вирішує скільки думати                     ║
║  │   → Interleaved thinking: reasoning МІЖ tool calls             ║
║  └── thinking blocks → НЕ видимі для user (internal reasoning)    ║
║                                                                    ║
║  LEGACY (Haiku 4.5 only):                                          ║
║  ├── thinking.type: "enabled"                                      ║
║  ├── thinking.budget_tokens: 1024-128000                           ║
║  └── Працює ТІЛЬКИ на Haiku 4.5 та older models                   ║
║                                                                    ║
║  NanoClaw стратегія (див. §3.4 для деталей):                       ║
║  ├── Reasoning tasks → effort: max (Opus 4.6)                      ║
║  ├── Complex generation → effort: high (Sonnet 4.6)                ║
║  ├── Routine tasks → effort: medium (Sonnet 4.6)                   ║
║  ├── Simple tasks → effort: low або disabled (Haiku)               ║
║  └── Cost guard: effort level CAP per skill type in manifest       ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  C. PROMPT CACHING                                                  ║
║  ─────────────────                                                  ║
║  Mechanism: cache_control.type = "ephemeral"                       ║
║  ├── Explicit: cache_control на конкретних content blocks          ║
║  ├── Auto-caching: cache_control на top-level (GA, Feb 2026)       ║
║  ├── auto-TTL: 5 хвилин (production)                               ║
║  ├── extended-TTL: 1 година (1h write cost = 2x base)              ║
║  ├── Read cost: 0.1x (90% discount)                                ║
║  ├── Write cost: 1.25x (5min) або 2.0x (1h)                       ║
║  └── Min cacheable tokens (⚠️ varies by model!):                   ║
║      ├── Sonnet 4.5/4.6: 1024 tokens                               ║
║      ├── Opus 4.6: 4096 tokens                                     ║
║      └── Haiku 4.5: 4096 tokens                                    ║
║                                                                    ║
║  NanoClaw caching strategy:                                         ║
║  ├── Layer 1+2 COMBINED (Foundation + Company): ALWAYS cached      ║
║  │   ~5000-10000 tokens → ≥4096 threshold MET на Opus/Haiku       ║
║  │   ⚠️ Foundation alone (~2000 tok) < 4096 → NOT cacheable        ║
║  │   on Opus! ТОМУ кешуємо Foundation+Company як єдиний блок      ║
║  │   Cache hit rate: ~95% (invalidated only on /update-context)   ║
║  ├── Layer 3 (Skill + memory): cached PER SKILL TYPE               ║
║  │   ~1000-3000 tokens — cacheable ТІЛЬКИ на Sonnet (≥1024)       ║
║  │   NOT cacheable on Opus/Haiku (< 4096)                          ║
║  │   Cache hit rate: ~70% on Sonnet, 0% on Opus/Haiku             ║
║  ├── Tools definitions: cached AS PART OF system                   ║
║  │   MCP tool schemas = stable → high cache hit rate               ║
║  └── ORDERING: cache_control на НАЙДОВШИЙ стабільний блок першим  ║
║     system = [foundation+company{cache}, skill+memory]            ║
║                                                                    ║
║  COST IMPACT (corrected for combined L1+L2):                        ║
║  ├── Without caching: ~11K tokens × $3/MTok = $0.033/request      ║
║  ├── With caching (Sonnet): ~8K cached × $0.3/MTok + ~3K new      ║
║  │   = $0.0024 + $0.009 = $0.0114/request                          ║
║  ├── With caching (Opus): ~5K cached × $0.5/MTok + ~6K new        ║
║  │   = $0.0025 + $0.030 = $0.0325/request (less savings)           ║
║  └── Savings: ~65% Sonnet, ~15% Opus per request                   ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  D. BATCH API                                                       ║
║  ──────────                                                         ║
║  POST /v1/messages/batches                                          ║
║  ├── Format: .jsonl (один request per line)                        ║
║  ├── Cost: 50% discount vs standard API                             ║
║  ├── Processing window: до 24 годин                                 ║
║  ├── Max batch size: 100,000 requests                               ║
║  ├── Result: GET /v1/messages/batches/{id}/results                 ║
║  └── Status polling: GET /v1/messages/batches/{id}                 ║
║                                                                    ║
║  NanoClaw використання:                                             ║
║  ├── Flow I (Batch Processing): масова генерація контенту          ║
║  ├── Combined with caching: ~95% savings vs individual             ║
║  │   Batch (50%) + Cache (40%) = combined discount                  ║
║  ├── Use cases:                                                     ║
║  │   ├── 30 Telegram posts for monthly content plan                ║
║  │   ├── 50 LinkedIn variations for A/B testing                     ║
║  │   ├── 100 email subject lines for newsletter                    ║
║  │   └── Bulk competitor analysis across N companies               ║
║  └── Orchestration: хост-процес, НЕ контейнер (деталі у Flow I)   ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  E. COMPACTION API (Beta — compact-2026-01-12)                     ║
║  ─────────────────────────────────────────────                      ║
║  Activation:                                                        ║
║  ├── Beta header: anthropic-beta: compact-2026-01-12               ║
║  ├── АБО: context_management.edits: ["compact_20260112"]           ║
║  ├── Серверна компресія conversation history                        ║
║  ├── Зберігає semantic meaning, видаляє redundancy                 ║
║  ├── Available: Opus 4.6, Sonnet 4.6                                ║
║  ├── ⚠️ З 1M context (beta) — compaction менш критичний            ║
║  └── NanoClaw: Flow A → коли conversation tokens > 100K → compact ║
║                                                                    ║
║  NanoClaw integration:                                              ║
║  ├── Trigger: conversation_tokens > COMPACTION_THRESHOLD (100K)    ║
║  ├── Action: compact → зберегти compacted history                   ║
║  ├── Memory: критичні факти → facts.jsonl ПЕРЕД compaction         ║
║  ├── User notice: "💬 Розмову оптимізовано для продовження"       ║
║  └── Fallback: якщо compaction unavailable → manual summary        ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  F. STRUCTURED OUTPUTS                                              ║
║  ──────────────────────                                             ║
║  response_format: { type: "json_schema", json_schema: {...} }      ║
║  ├── Гарантована відповідність JSON схемі                          ║
║  ├── Constrained decoding (не post-processing)                      ║
║  └── Use case: коли output = structured data для IPC               ║
║                                                                    ║
║  NanoClaw використання:                                             ║
║  ├── fact extraction → facts.jsonl format guaranteed                ║
║  ├── decision extraction → decisions.jsonl format guaranteed       ║
║  ├── skill output metadata (confidence, evidence_grade)             ║
║  ├── IPC response files (tool results)                              ║
║  └── Pipeline handoff data (structured context between agents)     ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  G. STREAMING (SSE)                                                 ║
║  ──────────────────                                                 ║
║  stream: true → Server-Sent Events                                  ║
║  ├── Events: message_start, content_block_*, message_delta, stop   ║
║  ├── Tool use: tool_use content blocks in stream                   ║
║  ├── Thinking: thinking blocks (if enabled) before content         ║
║  └── Error: error event with type + message                        ║
║                                                                    ║
║  NanoClaw → Telegram streaming pipeline:                            ║
║  ├── Claude SSE → container-runner.ts buffer                       ║
║  ├── PRIMARY: sendMessageDraft (✅ Bot API 9.3, native streaming)  ║
║  ├── FALLBACK: editMessage (debounce 300ms, for old clients)       ║
║  ├── MarkdownV2 escaping on each chunk                              ║
║  ├── Final: editMessage with complete response + reply_markup      ║
║  └── Cross-ref: Flow A (Phase 4), sendMessageDraft (Phase 2)      ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  H. CODE EXECUTION (Tool Use)                                       ║
║  ──────────────────────────────                                     ║
║  type: "computer_use_tool" або "code_execution" tool               ║
║  ├── Sandbox: ізольоване середовище                                ║
║  ├── Cost: безкоштовно (включено)                                  ║
║  ├── Languages: Python primary                                      ║
║  └── Available з: web search, fetch                                ║
║                                                                    ║
║  NanoClaw: обмежене використання:                                   ║
║  ├── Bash tool = PRIMARY code execution (container-level)          ║
║  ├── Claude code execution = SECONDARY (data analysis, charts)     ║
║  └── Контейнер вже є sandbox → Claude sandbox = nested isolation   ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  I. TOOL USE (Function Calling)                                     ║
║  ──────────────────────────────                                     ║
║  tools[]: масив tool definitions                                    ║
║  ├── name, description, input_schema (JSON Schema)                 ║
║  ├── tool_choice: auto | any | {name} | none                      ║
║  ├── Max tools: рекомендовано ≤64 (performance degrades over)      ║
║  └── Tool Search: динамічне виявлення з великих каталогів          ║
║      (deferred: true — не в першій версії)                         ║
║                                                                    ║
║  NanoClaw tool architecture:                                        ║
║  ├── IPC tools (завжди): read_file, write_file, request_hitl,      ║
║  │   send_message, search_facts, log_decision, schedule_task       ║
║  ├── MCP tools (per-skill): web_search, fetch, browser, etc.       ║
║  ├── Bash tool: execute commands in container                       ║
║  └── CONTEXT BUDGET PROBLEM:                                       ║
║      5 MCP × 10 tools × 200 tokens/definition = 10K tokens         ║
║      → Рішення: selective loading per skill type                   ║
║      → Skill manifest declares required_tools[]                    ║
║      → container-runner loads ONLY declared tools                   ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.3 МОДЕЛЬНИЙ МАТРИКС

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  MODEL SELECTION MATRIX                                            ║
║  ═══════════════════════                                           ║
║                                                                    ║
║  ПРИНЦИП: "Найменша модель що вирішує задачу"                     ║
║  Scale Paradox: більші моделі галюцинують більше                   ║
║  (Opus ~10% vs Sonnet <5% hallucination rate)                      ║
║                                                                    ║
║  ┌──────────────┬──────────────┬────────────┬────────────────┐    ║
║  │ Тип задачі    │ Модель        │ Thinking    │ Використання    │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ REASONING     │ Opus 4.6     │ effort:max │ Стратегія,       │    ║
║  │ (аналіз,     │ $5/$25       │            │ аудит, складні   │    ║
║  │ стратегія)    │              │            │ рішення, market  │    ║
║  │               │              │            │ intelligence     │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ GENERATION    │ Sonnet 4.6   │ effort:    │ Контент, копі,   │    ║
║  │ (створення   │ $3/$15       │ high       │ email, posts,    │    ║
║  │ контенту)    │              │            │ описи            │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ EXTRACTION    │ Sonnet 4.6   │ effort:    │ Парсинг даних,   │    ║
║  │ (витягування │ + Structured │ low        │ fact extraction,  │    ║
║  │ даних)       │ Outputs      │            │ memory update    │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ CLASSIFICATION│ Haiku 4.5    │ disabled   │ Routing, triage, │    ║
║  │ (маршрутизація│ $1/$5        │            │ intent detection, │    ║
║  │ та сортування)│              │            │ risk assessment  │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ SUB-AGENT     │ Haiku 4.5    │ effort:    │ Допоміжні задачі │    ║
║  │ (підзадачі)  │ $1/$5        │ medium     │ у pipeline,      │    ║
║  │               │              │ (legacy)   │ validation steps │    ║
║  ├──────────────┼──────────────┼────────────┼────────────────┤    ║
║  │ REAL-TIME     │ Haiku 4.5    │ disabled   │ Chat response,   │    ║
║  │ (інтерактив) │ $1/$5        │            │ quick answers,   │    ║
║  │               │              │            │ HITL processing  │    ║
║  └──────────────┴──────────────┴────────────┴────────────────┘    ║
║                                                                    ║
║  PIPELINE MODEL ROUTING (Flow D):                                  ║
║  ────────────────────────────────                                   ║
║                                                                    ║
║  Content Pipeline приклад:                                          ║
║  ├── Step 1: Topic research     → Sonnet + effort:high             ║
║  ├── Step 2: Outline            → Sonnet + effort:high             ║
║  ├── Step 3: HITL approval      → (no model, UI only)              ║
║  ├── Step 4: Draft writing      → Sonnet + effort:high             ║
║  ├── Step 5: Quality audit      → Opus + effort:max                ║
║  ├── Step 6: Formatting         → Haiku (apply channel adaptor)    ║
║  └── Step 7: HITL final review  → (no model, UI only)              ║
║                                                                    ║
║  Strategic Analysis приклад:                                        ║
║  ├── Step 1: Data gathering     → Sonnet + web search tools        ║
║  ├── Step 2: Deep analysis      → Opus + effort:max                ║
║  ├── Step 3: Recommendations    → Opus + effort:max                ║
║  └── Step 4: Report formatting  → Haiku (apply file_output adaptor)║
║                                                                    ║
║  COST PER PIPELINE:                                                 ║
║  ├── Simple task (1 step):     $0.01-0.03 (Haiku/Sonnet)          ║
║  ├── Standard pipeline (4-5):  $0.05-0.15 (mixed models)          ║
║  ├── Complex analysis (3-4):   $0.20-0.50 (includes Opus)         ║
║  └── Batch generation (30×):   $0.05-0.10 (Batch API + caching)   ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.4 EXTENDED THINKING — СТРАТЕГІЯ

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  THINKING STRATEGY MATRIX (Adaptive Thinking, Feb 2026)            ║
║  ════════════════════════════════════════════════════              ║
║                                                                    ║
║  ⚠️ budget_tokens DEPRECATED на Opus 4.6 / Sonnet 4.6              ║
║  Замінено на `effort` параметр + interleaved thinking            ║
║                                                                    ║
║  ┌─────────────────┬──────────────┬─────────────────────────┐    ║
║  │ Стратегія        │ Параметр      │ Коли використовувати      │    ║
║  ├─────────────────┼──────────────┼─────────────────────────┤    ║
║  │ MAX              │ effort: max  │ Opus 4.6: стратегічні     │    ║
║  │                  │ (deep think) │ рішення, аудит, складні   │    ║
║  │                  │              │ проблеми, competitive     │    ║
║  ├─────────────────┼──────────────┼─────────────────────────┤    ║
║  │ HIGH (default)   │ effort: high │ Sonnet: content creation, │    ║
║  │                  │ (standard)   │ outline, draft, copy.     │    ║
║  │                  │              │ Default for most tasks   │    ║
║  ├─────────────────┼──────────────┼─────────────────────────┤    ║
║  │ MEDIUM           │ effort:medium│ Sub-agents, validation,  │    ║
║  │                  │ (light)      │ extraction, translation  │    ║
║  ├─────────────────┼──────────────┼─────────────────────────┤    ║
║  │ LOW              │ effort: low  │ Екстракція даних, simple │    ║
║  │                  │ (minimal)    │ formatting, data parsing │    ║
║  ├─────────────────┼──────────────┼─────────────────────────┤    ║
║  │ DISABLED         │ (omit param) │ Haiku: routing, triage,  │    ║
║  │                  │              │ chat, HITL processing    │    ║
║  └─────────────────┴──────────────┴─────────────────────────┘    ║
║                                                                    ║
║  IMPORTANT CONSTRAINTS:                                            ║
║  ├── Thinking tokens = BILLED AS OUTPUT ($15-25/MTok for Opus!)   ║
║  ├── Interleaved thinking: reasoning МІЖ tool calls (4.6 only)    ║
║  ├── thinking content = NOT visible to end user (internal only)   ║
║  ├── NanoClaw: НІКОЛИ не передає thinking blocks до Telegram      ║
║  └── Effort CAP per skill: визначається у skill manifest          ║
║      "thinking": { "max_effort": "high" }                          ║
║                                                                    ║
║  WARMTH-ACCURACY TRADEOFF (Apart Research 2025):                   ║
║  ├── Warm/friendly system prompts → +10-30% errors                ║
║  ├── РІШЕННЯ: Tone isolation на handoffs                           ║
║  │   ├── Analytical agents: neutral, precise system prompt        ║
║  │   ├── Creative agents: warm, brand-voice system prompt         ║
║  │   └── Handoff: strip tone metadata, pass only structured data  ║
║  └── Cross-ref: §5 Виявлені Гепи у claude.md                     ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.5 MCP КОНЕКТОРИ ТА CONTEXT BUDGET

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  MCP (Model Context Protocol) ARCHITECTURE                         ║
║  ══════════════════════════════════════════                         ║
║                                                                    ║
║  ПРИНЦИП: MCP tools = зовнішні capabilities доступні агенту       ║
║  через стандартний протокол. NanoClaw → MCP server → зовнішній    ║
║  сервіс.                                                           ║
║                                                                    ║
║  MCP CONNECTOR CATALOGUE:                                          ║
║  ─────────────────────────                                         ║
║                                                                    ║
║  ┌─────────────────┬───────────────────────────────────────────┐ ║
║  │ Connector         │ Tools / Capabilities                       │ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Web Search        │ search(query) → результати пошуку          │ ║
║  │ (Brave/Google)    │ ~3-5 tools, ~500 tokens definition          │ ║
║  │                   │ USE: market research, competitor analysis   │ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Web Fetch         │ fetch(url) → page content as markdown      │ ║
║  │                   │ ~2-3 tools, ~300 tokens definition          │ ║
║  │                   │ USE: scraping, data extraction, verification│ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Filesystem        │ read/write/list/search local files          │ ║
║  │                   │ ~8-10 tools, ~800 tokens definition         │ ║
║  │                   │ USE: context/memory access, output saving   │ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Git               │ status/diff/log/commit                      │ ║
║  │                   │ ~5-7 tools, ~500 tokens definition          │ ║
║  │                   │ USE: canonical store management             │ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Google Drive      │ list/read/create/update files               │ ║
║  │ (Future)          │ ~6-8 tools, ~600 tokens definition          │ ║
║  │                   │ USE: Claude.ai sync, document collaboration │ ║
║  ├─────────────────┼───────────────────────────────────────────┤ ║
║  │ Custom IPC        │ NanoClaw-specific IPC tools                 │ ║
║  │ (built-in)        │ request_hitl, send_message, search_facts,  │ ║
║  │                   │ log_decision, schedule_task, tg_* tools     │ ║
║  │                   │ ~15-20 tools, ~1500 tokens definition       │ ║
║  │                   │ USE: NanoClaw integration layer             │ ║
║  └─────────────────┴───────────────────────────────────────────┘ ║
║                                                                    ║
║  CONTEXT BUDGET MANAGEMENT (🔴 Critical Gap):                      ║
║  ─────────────────────────────────────────────                     ║
║                                                                    ║
║  ПРОБЛЕМА:                                                         ║
║  ├── All tool definitions = context tokens                          ║
║  ├── 5 MCPs × 10 tools × 200 tokens = 10,000 tokens               ║
║  ├── + System prompt (~5000-11000 tokens)                          ║
║  ├── + Conversation history (~1000-50000 tokens)                   ║
║  ├── = 16K-71K tokens ЗАЙНЯТО до початку задачі                    ║
║  └── Model context: 200K (effectively ~130-180K for output)        ║
║                                                                    ║
║  РІШЕННЯ — SELECTIVE TOOL LOADING:                                  ║
║  ─────────────────────────────────                                  ║
║                                                                    ║
║  1. Skill Manifest declares required_tools[]:                       ║
║     ```yaml                                                         ║
║     # skills/marketing/content/copywriter/SKILL.md                 ║
║     required_tools:                                                 ║
║       - ipc:core          # request_hitl, send_message (always)    ║
║       - ipc:memory        # search_facts, log_decision             ║
║       - mcp:web_search    # for research-based content             ║
║     optional_tools:                                                 ║
║       - mcp:web_fetch     # if url provided by user                ║
║     ```                                                             ║
║                                                                    ║
║  2. container-runner.ts loads ONLY declared tools:                   ║
║     ├── Parse skill manifest                                        ║
║     ├── Load required_tools[] → tools array                         ║
║     ├── Conditionally load optional_tools[] based on user input     ║
║     ├── IPC core tools: ALWAYS loaded (~500 tokens)                 ║
║     └── Total tool budget target: ≤3000 tokens per request          ║
║                                                                    ║
║  3. Tool budgets per category:                                      ║
║     ├── Tier 1 (always): IPC core = ~500 tokens                    ║
║     ├── Tier 2 (skill-required): 1-2 MCPs = ~800-1600 tokens      ║
║     ├── Tier 3 (optional): 0-1 MCPs = ~0-800 tokens               ║
║     └── MAX: ~3000 tokens for tools (hard cap)                      ║
║                                                                    ║
║  FUTURE: Tool Search (deferred: true)                               ║
║  ├── Коли кількість tools > 64 → Tool Search API                   ║
║  ├── Claude динамічно виявляє потрібні tools                        ║
║  └── Не в першій версії NanoClaw                                   ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.6 CONTAINER ↔ CLAUDE SDK ІНТЕГРАЦІЯ

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  ARCHITECTURE: How container-runner uses Claude API                 ║
║  ═══════════════════════════════════════════════════                ║
║                                                                    ║
║  container-runner.ts — центральний модуль NanoClaw що:             ║
║  ├── Приймає задачу від telegram.ts (message + routing)             ║
║  ├── Збирає 3-layer system prompt                                   ║
║  ├── Завантажує skill + tools                                       ║
║  ├── Робить Claude API виклик                                       ║
║  └── Повертає результат → telegram.ts → user                       ║
║                                                                    ║
║  SYSTEM PROMPT ASSEMBLY (3 layers):                                 ║
║  ──────────────────────────────────                                  ║
║                                                                    ║
║  Layer 1: Foundation (~2000 tokens) [CACHED]                        ║
║  ┌──────────────────────────────────────────────────────────────┐ ║
║  │ You are NanoClaw, an AI marketing department OS.                │ ║
║  │                                                                  │ ║
║  │ ## Core Rules                                                    │ ║
║  │ - Evidence-graded outputs (MECE methodology)                    │ ║
║  │ - Ukrainian language for all content                             │ ║
║  │ - HITL for destructive/publishing actions                       │ ║
║  │ - Memory: read CLAUDE.md, update after task                     │ ║
║  │ - Cost awareness: log all API usage                              │ ║
║  │                                                                  │ ║
║  │ ## Output Format                                                 │ ║
║  │ [channel adaptor rules loaded here]                             │ ║
║  │                                                                  │ ║
║  │ ## Tool Usage                                                    │ ║
║  │ [IPC protocol: how to use request_hitl, send_message, etc.]    │ ║
║  │                                                                  │ ║
║  │ {cache_control: {type: "ephemeral"}}                            │ ║
║  └──────────────────────────────────────────────────────────────┘ ║
║                                                                    ║
║  Layer 2: Company Context (~3000-8000 tokens) [CACHED per company] ║
║  ┌──────────────────────────────────────────────────────────────┐ ║
║  │ ## Company: ЯКоманда                                            │ ║
║  │ [context/company/identity.md]                                    │ ║
║  │ [context/product/spec.md + pricing.md]                           │ ║
║  │ [context/audience/icp.md + jtbd.md]                              │ ║
║  │ [context/brand/voice.md]                                         │ ║
║  │ [context/market/intelligence.md]                                 │ ║
║  │                                                                  │ ║
║  │ {cache_control: {type: "ephemeral"}}                            │ ║
║  └──────────────────────────────────────────────────────────────┘ ║
║                                                                    ║
║  Layer 3: Skill + Memory (~1000-3000 tokens) [partial cache]       ║
║  ┌──────────────────────────────────────────────────────────────┐ ║
║  │ ## Current Task: [skill SKILL.md content]                       │ ║
║  │                                                                  │ ║
║  │ ## Memory                                                        │ ║
║  │ [CLAUDE.md content — identity, priorities, recent activity]     │ ║
║  │                                                                  │ ║
║  │ ## Relevant Facts                                                │ ║
║  │ [top 20 facts from facts.jsonl, topic-filtered]                 │ ║
║  │                                                                  │ ║
║  │ ## Recent Decisions                                              │ ║
║  │ [last 10 from decisions.jsonl]                                  │ ║
║  └──────────────────────────────────────────────────────────────┘ ║
║                                                                    ║
║  TOTAL: 6000-13000 tokens system prompt                             ║
║  + 500-3000 tokens tools                                            ║
║  = 6500-16000 tokens FIXED per request                              ║
║                                                                    ║
║  CONTAINER LIFECYCLE:                                               ║
║  ────────────────────                                               ║
║                                                                    ║
║  ① telegram.ts receives message                                     ║
║  ② Route: determine company + skill + model                         ║
║  ③ Assemble system prompt (3 layers + tools)                        ║
║  ④ Create Anthropic client:                                         ║
║     const client = new Anthropic({ apiKey: CLAUDE_API_KEY })       ║
║  ⑤ Call Messages API:                                               ║
║     const response = await client.messages.create({                 ║
║       model: selected_model,                                        ║
║       system: assembled_system_prompt,                               ║
║       messages: conversation_messages,                               ║
║       max_tokens: skill_max_tokens || 4096,                          ║
║       tools: loaded_tools,                                           ║
║       stream: true,                                                  ║
║       thinking: skill_thinking_config || undefined,                  ║
║       metadata: { user_id: company_id }                              ║
║     })                                                               ║
║  ⑥ Stream processing:                                               ║
║     ├── Accumulate content blocks                                   ║
║     ├── Handle tool_use → execute tool → return result              ║
║     ├── Stream text to Telegram (debounced editMessage)             ║
║     └── On stop → finalize response                                 ║
║  ⑦ Post-run hooks:                                                  ║
║     ├── Memory update (Flow G)                                      ║
║     ├── Cost logging (Flow J)                                       ║
║     └── Git commit (async)                                          ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  TOOL EXECUTION LOOP:                                               ║
║  ─────────────────────                                              ║
║                                                                    ║
║  Claude може повернути tool_use у response:                         ║
║  ├── Parse tool_use block: { name, id, input }                     ║
║  ├── IPC tools → write to /ipc/{group}/{tool}/                     ║
║  │   └── Wait for host response (polling or watcher)               ║
║  ├── MCP tools → forward to MCP server                              ║
║  │   └── Return result to Claude as tool_result                    ║
║  ├── Bash tool → execute in container                               ║
║  │   └── Return stdout/stderr as tool_result                       ║
║  ├── Send tool_result back to Claude:                               ║
║  │   messages.push({ role: "user", content: [{                     ║
║  │     type: "tool_result", tool_use_id: id, content: result       ║
║  │   }]})                                                           ║
║  └── Continue loop until Claude sends text (no more tool_use)      ║
║                                                                    ║
║  MAX TOOL ITERATIONS: 10 (prevent infinite loops)                   ║
║  TIMEOUT per tool: 30 seconds (60s for web operations)              ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.7 SESSION MANAGEMENT PER RUNTIME

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  4 RUNTIMES — SESSION ARCHITECTURE                                 ║
║  ═════════════════════════════════                                  ║
║                                                                    ║
║  ┌──────────────┬────────────────────────────────────────────┐   ║
║  │ Runtime       │ Session Model                                │   ║
║  ├──────────────┼────────────────────────────────────────────┤   ║
║  │ NanoClaw     │ STATELESS per request                         │   ║
║  │ (Primary)    │ ├── Кожен request = new container              │   ║
║  │              │ ├── Context = 3-layer system prompt            │   ║
║  │              │ ├── Memory = CLAUDE.md + facts + decisions     │   ║
║  │              │ ├── History = last N messages from Telegram    │   ║
║  │              │ └── No persistent Claude session               │   ║
║  ├──────────────┼────────────────────────────────────────────┤   ║
║  │ Claude.ai    │ PERSISTENT conversation                       │   ║
║  │ (Escape)     │ ├── Full 200K context window                   │   ║
║  │              │ ├── Session transfer via session_transfer.md   │   ║
║  │              │ ├── Manual: copy/paste context package         │   ║
║  │              │ ├── Future: MCP Google Drive auto-sync         │   ║
║  │              │ └── Return: /import-analysis → memory update  │   ║
║  ├──────────────┼────────────────────────────────────────────┤   ║
║  │ Claude Code  │ PERSISTENT terminal session                   │   ║
║  │ (Dev)        │ ├── Git-based sync with canonical store       │   ║
║  │              │ ├── git pull → see latest memory/context       │   ║
║  │              │ ├── git push → NanoClaw sync.sh reads changes │   ║
║  │              │ └── Full filesystem access                     │   ║
║  ├──────────────┼────────────────────────────────────────────┤   ║
║  │ Cowork       │ TASK-BASED session                            │   ║
║  │ (Background) │ ├── Delegate and forget                       │   ║
║  │              │ ├── Web research → file output                │   ║
║  │              │ └── Result pickup via shared filesystem       │   ║
║  └──────────────┴────────────────────────────────────────────┘   ║
║                                                                    ║
║  SESSION TRANSFER PROTOCOL (Cross-ref: Flow B, Phase 4):          ║
║  ─────────────────────────────────────────────────────             ║
║                                                                    ║
║  NanoClaw → Claude.ai:                                              ║
║  ├── Generate session_transfer.md:                                  ║
║  │   ├── memory/ snapshot (CLAUDE.md + recent facts + decisions)   ║
║  │   ├── Current task context                                       ║
║  │   ├── Relevant company context files                             ║
║  │   └── Instructions for Claude.ai session                        ║
║  ├── Delivery: send as Telegram document + "відкрийте в Claude.ai" ║
║  └── Return path: /import-analysis command                          ║
║                                                                    ║
║  NanoClaw ↔ Claude Code:                                            ║
║  ├── Sync mechanism: Git (canonical store)                          ║
║  ├── Claude Code sees: full repo + memory/ + context/               ║
║  ├── Claude Code writes: skills/, tools/, tests/                    ║
║  └── NanoClaw picks up: sync.sh polls git changes                   ║
║                                                                    ║
║  Priority on conflict: NanoClaw > Claude Code > Claude.ai          ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.8 RATE LIMITS, ERROR HANDLING, RETRY

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  CLAUDE API RATE LIMITS:                                           ║
║  ═══════════════════════                                           ║
║                                                                    ║
║  Tier-based (per organization, Feb 2026):                           ║
║  ⚠️ Limits use ITPM (Input Tokens/Min) + OTPM (Output Tokens/Min)  ║
║                                                                    ║
║  ┌───────┬──────┬────────────────┬──────────────┬───────────┐   ║
║  │ Tier  │ RPM  │ ITPM            │ OTPM          │ 1M context│   ║
║  ├───────┼──────┼────────────────┼──────────────┼───────────┤   ║
║  │ 1     │ 50   │ 30K-50K         │ 8K-10K        │ ✘          │   ║
║  │ 2     │ 1000 │ 100K-450K       │ 40K-80K       │ ✘          │   ║
║  │ 3     │ 2000 │ 800K-1M         │ 160K-200K     │ ✘          │   ║
║  │ 4     │ 4000 │ 400K-4M         │ 400K-800K     │ ✔ (beta)   │   ║
║  └───────┴──────┴────────────────┴──────────────┴───────────┘   ║
║  ⚠️ ITPM/OTPM varies by model within same tier!                    ║
║  └── NanoClaw target: Tier 2 (1000 RPM, sufficient for MVP)       ║
║                                                                    ║
║  NanoClaw needs (per-company estimates):                            ║
║  ├── Peak: ~10 requests/min (active owner interaction)              ║
║  ├── Scheduled: ~2-5 requests/hour (cron tasks)                    ║
║  ├── Batch: variable (processed by Batch API, not counted)         ║
║  └── Total multi-company: N × 10 RPM peak → Tier 2 sufficient     ║
║      for up to ~5-10 active companies simultaneously               ║
║                                                                    ║
║  ERROR HANDLING CASCADE:                                            ║
║  ─────────────────────────                                          ║
║                                                                    ║
║  ┌──────────┬────────────────────────────────────────────────┐   ║
║  │ HTTP Code │ NanoClaw Response                                │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 200 OK   │ Process response normally                         │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 400      │ Log error + notify owner: "Помилка запиту"        │   ║
║  │ Bad Req  │ DO NOT retry (request is malformed)               │   ║
║  │          │ Debug: log full request for analysis               │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 401      │ API key invalid → CRITICAL ALERT to owner         │   ║
║  │ Unauth   │ Pause all operations until key updated            │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 429      │ Rate limited → exponential backoff:               │   ║
║  │ Too Many │ ├── Wait: 1s → 2s → 4s → 8s → 16s → fail        │   ║
║  │          │ ├── Max retries: 5                                 │   ║
║  │          │ ├── If company-level: queue request                │   ║
║  │          │ └── If persistent: downgrade model tier            │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 500      │ Server error → retry with backoff                 │   ║
║  │ Internal │ ├── Wait: 2s → 4s → 8s                            │   ║
║  │          │ ├── Max retries: 3                                 │   ║
║  │          │ └── If persistent: fallback to different model     │   ║
║  ├──────────┼────────────────────────────────────────────────┤   ║
║  │ 529      │ API overloaded → queue + wait                     │   ║
║  │ Overload │ ├── Wait: 30s → 60s → 120s                        │   ║
║  │          │ ├── Notify owner if wait > 2min                    │   ║
║  │          │ └── Fallback: Haiku (less load)                    │   ║
║  └──────────┴────────────────────────────────────────────────┘   ║
║                                                                    ║
║  MODEL FALLBACK CASCADE:                                            ║
║  ─────────────────────────                                          ║
║  If selected model fails:                                           ║
║  ├── Opus → fallback to Sonnet (with thinking:adaptive → fixed)    ║
║  ├── Sonnet → fallback to Haiku (with thinking:disabled)           ║
║  ├── Haiku → retry Haiku (last resort)                              ║
║  └── All fail → queue + alert owner: "⚠️ Claude API недоступний"  ║
║                                                                    ║
║  TIMEOUT MANAGEMENT:                                                ║
║  ├── Response start: wait max 30s (Haiku), 60s (Sonnet), 120s (Opus)║
║  ├── Stream gap: if no SSE event for 30s → timeout → retry         ║
║  ├── Total request: max 300s (5 min) → abort → notify              ║
║  └── Tool execution within request: max 30s per tool call           ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.9 COST OPTIMIZATION FRAMEWORK

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  COST OPTIMIZATION — 5 STRATEGIES                                  ║
║  ═══════════════════════════════                                   ║
║                                                                    ║
║  ┌──────────────────┬───────────────────┬────────────────────┐  ║
║  │ Strategy           │ Savings            │ Implementation       │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 1. Right-sizing    │ 60-80%             │ Haiku where possible│  ║
║  │    (model select)  │ Opus $25 vs        │ Model Matrix (§3.3) │  ║
║  │                    │ Haiku $5 output     │ per skill manifest  │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 2. Prompt Caching  │ 40% per request    │ 3-layer caching     │  ║
║  │                    │ 90% on cached part │ (§3.2-C)            │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 3. Batch API       │ 50% on batch       │ Flow I (Phase 4)    │  ║
║  │                    │ + caching = 70-95% │ Mass content gen    │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 4. Thinking budget │ 30-50% on complex  │ CAP per skill type  │  ║
║  │                    │ tasks              │ (§3.4)              │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 5. Token economy   │ 10-20%             │ Concise prompts,    │  ║
║  │                    │                    │ progressive detail, │  ║
║  │                    │                    │ selective tools      │  ║
║  ├──────────────────┼───────────────────┼────────────────────┤  ║
║  │ 6. Long-context   │ ⚠️ AVOID 2x cost  │ Keep input <200K    │  ║
║  │    awareness      │ for >200K input   │ tokens. Use Compact-│  ║
║  │                    │ ($6/$22.50 Sonnet) │ ion API if needed   │  ║
║  └──────────────────┴───────────────────┴────────────────────┘  ║
║                                                                    ║
║  BUDGET ALERT CASCADE (cross-ref: Flow J, Phase 4):               ║
║  ──────────────────────────────────────────────                    ║
║  ├── 80% budget → downgrade: Opus→Sonnet, Sonnet→Haiku           ║
║  ├── 95% budget → Haiku only                                       ║
║  ├── 100% budget → pause non-essential, alert owner                ║
║  └── Owner override: /budget-override +$N                          ║
║                                                                    ║
║  ESTIMATED MONTHLY COSTS (per company):                            ║
║  ─────────────────────────────────────                             ║
║                                                                    ║
║  Light usage (5-10 requests/day):                                   ║
║  ├── ~150-300 requests/month                                        ║
║  ├── Mix: 10% Opus, 60% Sonnet, 30% Haiku                         ║
║  ├── Without optimization: ~$15-30/month                           ║
║  └── With optimization:    ~$5-10/month                            ║
║                                                                    ║
║  Active usage (20-40 requests/day):                                 ║
║  ├── ~600-1200 requests/month                                       ║
║  ├── Mix: 15% Opus, 55% Sonnet, 30% Haiku                         ║
║  ├── Without optimization: ~$50-100/month                          ║
║  └── With optimization:    ~$15-35/month                           ║
║                                                                    ║
║  Heavy + batch content:                                             ║
║  ├── ~1000 interactive + 200 batch/month                           ║
║  ├── Without optimization: ~$80-200/month                          ║
║  └── With optimization:    ~$25-60/month                           ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3.10 UPDATES TO PREVIOUS PHASES

```
╔══════════════════════════════════════════════════════════════════╗
║  PHASE 3 DELTAS TO PHASE 1:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + container-runner.ts architecture fully specified                  ║
║  + 3-layer system prompt assembly detailed                          ║
║  + Tool loading strategy: selective per skill manifest              ║
║  + Model selection: not just per-agent, but per-STEP in pipeline   ║
║  + Session management per runtime fully specified                   ║
║  + Cost optimization as architectural principle                     ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 3 DELTAS TO PHASE 2:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Streaming pipeline: Claude SSE → buffer → Telegram editMessage  ║
║  + sendMessageDraft integration with Claude streaming               ║
║  + Voice I/O: model selection for transcription/synthesis tasks     ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 3 DELTAS TO PHASE 4:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Flow A: model + thinking selection per request now specified     ║
║  + Flow D: per-step model routing in pipeline                       ║
║  + Flow G: Structured Outputs for memory extraction guaranteed     ║
║  + Flow I: Batch API → full spec now in Phase 3 (§3.2-D)          ║
║  + Flow J: Cost tracking schema → pricing basis now documented     ║
║  + Compaction integration with Flow A for long conversations       ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## НАСТУПНІ ФАЗИ

```
ФАЗА 5: DEPLOYMENT, SECURITY & EVOLUTION
  Docker deployment specs. Secret management (API keys, tokens).
  Backup & disaster recovery. Monitoring & alerting.
  Security audit checklist. Scaling strategy.
  Quarterly roadmap Q1-Q4 2026.
```

---

*Фаза 3 завершена. Готовий до Фази 5.*
