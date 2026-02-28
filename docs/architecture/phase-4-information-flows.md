# NanoClaw OS — Генеральний Архітектурний План v5.0

**Version**: 5.0 FINAL
**Date**: 2026-02-28
**Status**: Кінцевий дизайн
**Scope**: Фаза 4 з 5 — INFORMATION FLOWS & MEMORY

---

## ФАЗА 4: INFORMATION FLOWS & MEMORY

---

### 4.1 РЕЄСТР ПОТОКІВ: 10 CANONICAL FLOWS

```
NanoClaw OS має рівно 10 інформаційних потоків.
Кожен потік — це детерміністичний шлях даних з визначеним
trigger'ом, учасниками, артефактами та точками відмови.

╔══════════════════════════════════════════════════════════════════╗
║  FLOW  │ НАЗВА                │ TRIGGER             │ ЧАСТОТА   ║
╠══════════════════════════════════════════════════════════════════╣
║  A     │ User → Agent → User  │ Повідомлення (TG)   │ ~85%      ║
║  B     │ Cross-Runtime Task   │ Session transfer cmd │ ~2%       ║
║  C     │ Agent → Agent        │ Handoff JSON         │ ~5%       ║
║  D     │ Multi-Agent Pipeline │ Process trigger      │ ~3%       ║
║  E     │ HITL Convention      │ Agent request        │ ~8%       ║
║  F     │ Scheduled Task       │ Cron/interval/once   │ ~10%      ║
║  G     │ Memory Lifecycle     │ Post-run hook        │ ~95%      ║
║  H     │ Context Evolution    │ Owner update         │ ~1%       ║
║  I     │ Batch Processing     │ Mass generation cmd  │ <1%       ║
║  J     │ Cost Tracking        │ Кожен API запит      │ 100%      ║
╚══════════════════════════════════════════════════════════════════╝

ПРИМІТКА: Частоти не адитивні — G і J працюють ПАРАЛЕЛЬНО з A-F.
Flow E є ПІДПОТОКОМ D (або A), а не окремим entry point.
```

---

### 4.2 FLOW A: USER → AGENT → USER (Основний потік)

```
85% усіх взаємодій NanoClaw — це Flow A.
Це КАНОНІЧНИЙ потік: повідомлення входить, обробляється, відповідь виходить.

╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║  ЕТАП 1: ВХІД (Telegram → SQLite)                                    ║
║  ─────────────────────────────────                                    ║
║                                                                       ║
║  Telegram Bot API                                                     ║
║  │                                                                    ║
║  │  getUpdates() / Webhook (long polling)                             ║
║  │  Повертає Update об'єкт:                                          ║
║  │  {                                                                 ║
║  │    update_id: 123456789,                                          ║
║  │    message: {                                                      ║
║  │      message_id: 42,                                              ║
║  │      from: { id: 7654321, first_name: "God" },                    ║
║  │      chat: { id: -1001234567890, type: "supergroup",              ║
║  │              title: "ЯКоманда" },                                 ║
║  │      date: 1709136000,                                             ║
║  │      text: "@Andy проаналізуй конкурентів",                       ║
║  │      // або: voice, document, photo, sticker, reply_to_message    ║
║  │    }                                                               ║
║  │  }                                                                 ║
║  ▼                                                                    ║
║  telegram.ts: NORMALIZE                                               ║
║  │                                                                    ║
║  │  Уніфіковане повідомлення:                                        ║
║  │  {                                                                 ║
║  │    id: "tg_42_-1001234567890",                                    ║
║  │    channel: "telegram",                                            ║
║  │    group_id: "yakomanda",          ← mapping: chat_id → group     ║
║  │    sender: "god",                  ← owner mapping                ║
║  │    type: "text",                   ← text|voice|document|photo    ║
║  │    content: "проаналізуй конкурентів",  ← trigger stripped        ║
║  │    raw_content: "@Andy проаналізуй конкурентів",                  ║
║  │    reply_to: null,                 ← thread context               ║
║  │    attachments: [],                                                ║
║  │    metadata: {                                                     ║
║  │      timestamp: "2026-02-28T14:30:00Z",                           ║
║  │      message_thread_id: null,      ← Forum topic ID               ║
║  │      is_forum_message: false                                       ║
║  │    }                                                               ║
║  │  }                                                                 ║
║  │                                                                    ║
║  │  VOICE HANDLING:                                                   ║
║  │  Якщо type=voice:                                                  ║
║  │    → getFile() → download OGA                                     ║
║  │    → ffmpeg OGA→WAV (якщо потрібно)                               ║
║  │    → Whisper API або Claude Vision → transcript                   ║
║  │    → content = transcript, type залишається "voice"                ║
║  │    → metadata.original_duration = 45s                              ║
║  │                                                                    ║
║  │  DOCUMENT/PHOTO HANDLING:                                          ║
║  │  Якщо type=document або photo:                                     ║
║  │    → getFile() → download до temp/                                 ║
║  │    → attachments = [{ path, mime_type, size }]                     ║
║  │    → Файл монтується у контейнер                                  ║
║  ▼                                                                    ║
║  db.ts: INSERT INTO messages                                          ║
║  │                                                                    ║
║  │  SQLite row:                                                       ║
║  │  ┌─────────────┬────────────────────────────────────┐             ║
║  │  │ id           │ AUTO INCREMENT                      │             ║
║  │  │ external_id  │ "tg_42_-1001234567890"              │             ║
║  │  │ group_id     │ "yakomanda"                          │             ║
║  │  │ sender       │ "god"                                │             ║
║  │  │ content      │ "проаналізуй конкурентів"           │             ║
║  │  │ type         │ "text"                               │             ║
║  │  │ attachments  │ "[]"                                 │             ║
║  │  │ metadata     │ '{"timestamp":"2026-02-28..."}'     │             ║
║  │  │ processed    │ 0                                    │             ║
║  │  │ created_at   │ 2026-02-28T14:30:00Z                │             ║
║  │  └─────────────┴────────────────────────────────────┘             ║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ЕТАП 2: ROUTING (Message Loop → Queue)                               ║
║  ──────────────────────────────────────                               ║
║                                                                       ║
║  startMessageLoop() — кожні MESSAGE_POLLING_INTERVAL ms (2000):       ║
║  │                                                                    ║
║  │  getNewMessages() → SELECT * FROM messages WHERE processed=0       ║
║  │  │                                                                 ║
║  │  ├── CHECK 1: Trigger pattern                                      ║
║  │  │   ├── Main group (admin): ЗАВЖДИ обробляє                      ║
║  │  │   └── Non-main group: ТІЛЬКИ якщо contains(TRIGGER_PATTERN)    ║
║  │  │       TRIGGER_PATTERN = "@Andy" (configurable в config.ts)     ║
║  │  │                                                                 ║
║  │  ├── CHECK 2: Group registration                                   ║
║  │  │   └── group_id IN registered_groups.json?                      ║
║  │  │       NO → ignore, mark processed=1                             ║
║  │  │                                                                 ║
║  │  ├── CHECK 3: Rate limiting (per-group)                            ║
║  │  │   └── Більше N повідомлень за M секунд?                        ║
║  │  │       YES → queue, respond "зачекай"                           ║
║  │  │                                                                 ║
║  │  └── ROUTE → group-queue.ts                                       ║
║  │                                                                    ║
║  ▼                                                                    ║
║  group-queue.ts:                                                      ║
║  │                                                                    ║
║  │  Архітектура:                                                      ║
║  │  ┌───────────────────────────────────────────────┐                ║
║  │  │  GLOBAL CONCURRENCY LIMIT = 3                  │                ║
║  │  │  (максимум 3 контейнери одночасно)             │                ║
║  │  │                                                 │                ║
║  │  │  Черги per-group (FIFO):                        │                ║
║  │  │  ├── yakomanda:  [msg_42] ← processing         │                ║
║  │  │  ├── course:     [msg_55, msg_56] ← waiting    │                ║
║  │  │  └── client-x:   [] ← idle                     │                ║
║  │  │                                                 │                ║
║  │  │  MESSAGE BATCHING:                              │                ║
║  │  │  Якщо 3+ повідомлення у черзі одної групи      │                ║
║  │  │  за BATCH_WINDOW (5 сек), вони об'єднуються    │                ║
║  │  │  в один контейнер-виклик для ефективності.     │                ║
║  │  └───────────────────────────────────────────────┘                ║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ЕТАП 3: CONTAINER SPAWN (Runtime Isolation)                          ║
║  ──────────────────────────────────────────                           ║
║                                                                       ║
║  container-runner.ts → runAgent():                                    ║
║  │                                                                    ║
║  │  ① Визначити company та group                                     ║
║  │     group_id="yakomanda" → company="yakomanda"                    ║
║  │     isMainGroup = (group_id === config.MAIN_GROUP)                ║
║  │                                                                    ║
║  │  ② Визначити skill (ROUTING DECISION)                             ║
║  │     ├── Thread enrichment: IF has_forums = true →                 ║
║  │     │   thread_hierarchy.json → routing_domain + allowed_skills   ║
║  │     │   (Cross-ref: Phase 0 §0.4 Forum Thread Hierarchy)         ║
║  │     ├── Explicit: "@Andy /competitor-analysis" → routing table    ║
║  │     ├── Implicit: Messages API Haiku classifier                   ║
║  │     │   Input: content + company context + thread hint             ║
║  │     │   Output: { skill: "marketing/market-intelligence/analyst",║
║  │     │            confidence: 0.87 }                                ║
║  │     │   Model: Haiku 4.5 (дешевий, швидкий, ~0.2 сек)            ║
║  │     │   Fallback: confidence < 0.5 → default skill                ║
║  │     └── Default: meta/orchestration/general-assistant              ║
║  │                                                                    ║
║  │  ③ Підготувати mount'и                                            ║
║  │                                                                    ║
║  │     READ-ONLY:                                                     ║
║  │     ┌─────────────────────────────────────────────────────┐       ║
║  │     │ /skill/     ← skills/{domain}/{area}/{role}/SKILL.md│       ║
║  │     │ /context/   ← companies/yakomanda/context/          │       ║
║  │     │ /foundation/← foundation/                            │       ║
║  │     │ /templates/ ← foundation/output_templates/           │       ║
║  │     │ /adaptors/  ← foundation/channel_adaptors/           │       ║
║  │     └─────────────────────────────────────────────────────┘       ║
║  │                                                                    ║
║  │     READ-WRITE:                                                    ║
║  │     ┌─────────────────────────────────────────────────────┐       ║
║  │     │ /memory/    ← companies/yakomanda/memory/            │       ║
║  │     │ /files/     ← groups/yakomanda/files/                │       ║
║  │     │ /session/   ← data/sessions/yakomanda/.claude/       │       ║
║  │     │ /ipc/       ← data/ipc/yakomanda/                    │       ║
║  │     └─────────────────────────────────────────────────────┘       ║
║  │                                                                    ║
║  │     NOT MOUNTED (ізоляція на рівні hypervisor/cgroups):           ║
║  │     ├── companies/client-x/         (інші компанії)               ║
║  │     ├── groups/client-x/            (інші групи)                  ║
║  │     ├── data/nanoclaw.db            (хост state)                  ║
║  │     ├── src/                         (NanoClaw код)                ║
║  │     └── mount-allowlist.json        (секʼюріті)                   ║
║  │                                                                    ║
║  │  ④ Spawn container                                                 ║
║  │     Docker: docker run --rm --network=host \                       ║
║  │       -v /skill:/skill:ro \                                        ║
║  │       -v /context:/context:ro \                                    ║
║  │       ... (all mounts) \                                           ║
║  │       nanoclaw-agent-runner                                        ║
║  │                                                                    ║
║  │  ⑤ Pass message payload                                           ║
║  │     ENV vars: GROUP_ID, COMPANY_ID, IS_MAIN, SENDER               ║
║  │     STDIN або файл: normalized message JSON                        ║
║  │                                                                    ║
║  │  ⑥ Typing indicator                                                ║
║  │     sendChatAction("typing") кожні 4 сек                          ║
║  │     (Telegram auto-clears після 5 сек)                            ║
║  │                                                                    ║
║  ▼                                                                    ║
║  КОНТЕЙНЕР ЗАПУЩЕНО                                                   ║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ЕТАП 4: AGENT EXECUTION (Inside Container)                           ║
║  ──────────────────────────────────────────                           ║
║                                                                       ║
║  agent-runner/src/index.ts:                                           ║
║  │                                                                    ║
║  │  ① CONTEXT ASSEMBLY (system prompt construction)                  ║
║  │                                                                    ║
║  │     3-шаровий system prompt (див. Фаза 3, §3.6):                 ║
║  │                                                                    ║
║  │     ┌──────────────────────────────────────────────────┐          ║
║  │     │ LAYER 1: IDENTITY + FOUNDATION (кешований, 82%↓) │          ║
║  │     │  /foundation/core_identity.md                     │          ║
║  │     │  /foundation/output_standards.md                  │          ║
║  │     │  /foundation/evidence_grading.md                  │          ║
║  │     │                                                    │          ║
║  │     │ LAYER 2: COMPANY CONTEXT (per-company, кешований) │          ║
║  │     │  /context/company/identity.md                     │          ║
║  │     │  /context/brand/voice.md                          │          ║
║  │     │  /context/audience/icp.md                         │          ║
║  │     │  /context/product/spec.md                         │          ║
║  │     │  ... (тільки релевантні для skill)                │          ║
║  │     │                                                    │          ║
║  │     │ LAYER 3: SKILL + MEMORY (динамічний)              │          ║
║  │     │  /skill/SKILL.md                                  │          ║
║  │     │  /memory/CLAUDE.md (останні ~50 записів)          │          ║
║  │     │  /memory/facts.jsonl (релевантні по topic)        │          ║
║  │     │  /memory/decisions.jsonl (останні 10)             │          ║
║  │     └──────────────────────────────────────────────────┘          ║
║  │                                                                    ║
║  │  ② CLAUDE AGENT SDK SESSION                                       ║
║  │                                                                    ║
║  │     const session = new ClaudeSession({                            ║
║  │       model: selectModel(task_complexity),                         ║
║  │       // Haiku: classification, simple Q&A                        ║
║  │       // Sonnet: content, analysis, standard tasks                ║
║  │       // Opus: strategy, complex reasoning, multi-step            ║
║  │       systemPrompt: assembled_prompt,                              ║
║  │       tools: [...mcp_tools, ...ipc_tools],                        ║
║  │       maxTurns: 25,                                                ║
║  │       thinking: { type: "enabled", budget: adaptive }             ║
║  │     });                                                            ║
║  │                                                                    ║
║  │  ③ EXECUTION LOOP                                                 ║
║  │     Claude iterates: think → act → observe → think → ...          ║
║  │                                                                    ║
║  │     Available actions:                                             ║
║  │     ├── bash: виконати команди в контейнері                       ║
║  │     ├── file read/write: тільки mounted paths                     ║
║  │     ├── MCP tools: web search, Notion, Canva, etc.                ║
║  │     ├── IPC send_message: відправити повідомлення                  ║
║  │     ├── IPC schedule_task: запланувати задачу                      ║
║  │     ├── IPC request_hitl: запросити рішення owner'а               ║
║  │     └── IPC register_group: тільки main group                     ║
║  │                                                                    ║
║  │  ④ RESULT GENERATION                                               ║
║  │     Claude формує відповідь з урахуванням:                        ║
║  │     ├── /templates/ → формат (analytical, creative, report)       ║
║  │     ├── /adaptors/telegram.md → Telegram formatting rules         ║
║  │     └── /context/brand/voice.md → tone of voice                   ║
║  │                                                                    ║
║  │  ⑤ POST-RUN HOOKS (КОЖЕН ЗАПУСК, без виключень)                  ║
║  │     ├── → Flow G: Memory Update                                    ║
║  │     ├── → Flow J: Cost Logging                                     ║
║  │     └── → Session state save                                       ║
║  │                                                                    ║
║  ▼                                                                    ║
║  STREAMING OUTPUT → stdout                                            ║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ЕТАП 5: OUTPUT DELIVERY (Container → Telegram)                       ║
║  ──────────────────────────────────────────────                       ║
║                                                                       ║
║  container-runner.ts:                                                 ║
║  │                                                                    ║
║  │  ① Читає streaming output від контейнера                          ║
║  │                                                                    ║
║  │  ② FILTER: видаляє <internal>...</internal> теги                  ║
║  │     (внутрішнє мислення агента, не для юзера)                     ║
║  │                                                                    ║
║  │  ③ DRAFT MODE (sendMessageDraft)                                  ║
║  │     Для довгих відповідей:                                        ║
║  │     ├── Перший чанк → editMessageText (streaming preview)         ║
║  │     ├── Кожні 500ms → editMessageText (update)                    ║
║  │     └── Final → editMessageText (complete)                        ║
║  │     Rate limit: не частіше 30/сек на групу (Telegram limit)       ║
║  │                                                                    ║
║  │  ④ Передає у router.ts                                            ║
║  │                                                                    ║
║  ▼                                                                    ║
║  router.ts:                                                           ║
║  │                                                                    ║
║  │  ROUTING LOGIC:                                                    ║
║  │  ├── target = message.target_group || original_group               ║
║  │  ├── format = apply channel_adaptors/telegram.md                  ║
║  │  └── method = determine_send_method(content)                      ║
║  │                                                                    ║
║  │  SEND METHOD SELECTION:                                            ║
║  │  ┌──────────────────────────────────────────────────────┐         ║
║  │  │ Content Type      │ Telegram Method        │ Limit   │         ║
║  │  ├──────────────────────────────────────────────────────┤         ║
║  │  │ Text ≤4096 chars  │ sendMessage             │ 4096ch  │         ║
║  │  │ Text >4096 chars  │ split + sendMessage ×N  │ per msg │         ║
║  │  │ Markdown          │ sendMessage (MD2 parse) │ 4096ch  │         ║
║  │  │ Image             │ sendPhoto               │ 10MB    │         ║
║  │  │ Document          │ sendDocument             │ 50MB    │         ║
║  │  │ Multi-image       │ sendMediaGroup           │ 10 items│         ║
║  │  │ Voice reply       │ sendVoice (TTS)          │ — ║         ║
║  │  │ With buttons      │ sendMessage + InlineKB   │ 100 btn │         ║
║  │  └──────────────────────────────────────────────────────┘         ║
║  │                                                                    ║
║  │  TEXT SPLITTING ALGORITHM:                                         ║
║  │  1. Спробуй розділити по \n\n (paragraph breaks)                  ║
║  │  2. Якщо paragraph > 4096, розділи по \n                           ║
║  │  3. Якщо рядок > 4096, розділи по sentence (". ")                 ║
║  │  4. Зберігай MarkdownV2 formatting контекст між чанками           ║
║  │  5. Кожен чанк ≤ 4096 символів                                    ║
║  │                                                                    ║
║  ▼                                                                    ║
║  telegram.ts: SEND                                                    ║
║  │                                                                    ║
║  │  MARKDOWNV2 ESCAPING (критично!):                                 ║
║  │  Символи що ЗАВЖДИ екрануються: _ * [ ] ( ) ~ ` > # + - = | { }  ║
║  │  КРІМ тих що є частиною formatting:                                ║
║  │  *bold* → \*не екранувати усередині\*                              ║
║  │  _italic_ → \_не екранувати усередині\_                            ║
║  │  `code` → \`не екранувати усередині\`                              ║
║  │  ```pre``` → не екранувати усередині                                ║
║  │  [text](url) → екранувати в text, не в url                        ║
║  │                                                                    ║
║  │  ERROR HANDLING:                                                   ║
║  │  ├── 429 Too Many Requests → exponential backoff (1s, 2s, 4s)     ║
║  │  ├── 400 Message too long → re-split and retry                    ║
║  │  ├── 400 Can't parse entities → strip formatting, send plain      ║
║  │  ├── 403 Bot blocked → mark group inactive                        ║
║  │  └── 5xx Server error → retry 3x with backoff                    ║
║  │                                                                    ║
║  ▼                                                                    ║
║  USER бачить відповідь у Telegram                                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

FLOW A — ТОЧКИ ВІДМОВИ ТА RECOVERY:

  ① Telegram API unavailable
     → Повідомлення не зберігається → втрачається
     → Мітигація: Telegram гарантує delivery після reconnect
       (long polling з offset)

  ② SQLite write failure
     → Повідомлення не записано → не буде обробленим
     → Мітигація: WAL mode, retry 3x, alert owner

  ③ Container spawn failure
     → Повідомлення залишається в черзі → retry через 30 сек
     → Після 3 retries → alert owner через main group

  ④ Claude API error (429/500/overloaded)
     → Agent SDK має built-in retry з exponential backoff
     → Після 5 retries → повідомляє юзера: "тимчасово недоступний"

  ⑤ IPC failure (файлова система)
     → Повідомлення від агента не доставлено
     → IPC Watcher retry кожну секунду
     → Orphan файли автоматично cleanup після 1 год

  ⑥ Telegram send failure
     → Спроба re-send 3x → зберегти в failed_messages table
     → Alert owner → manual retry через /retry-failed
```

---

### 4.3 FLOW B: CROSS-RUNTIME SESSION TRANSFER

```
Flow B активується коли задача потребує переходу між runtime'ами:
NanoClaw ↔ Claude.ai, NanoClaw ↔ Claude Code, або навпаки.

КЛЮЧОВИЙ ПРИНЦИП: Canonical Store (Git) = source of truth.
                   Session transfer = export/import через Git.

╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║  TRANSFER TYPE 1: NANOCLAW → CLAUDE.AI                                ║
║  (Для: глибокий аналіз, 200K+ контекст, артефакти)                   ║
║  ─────────────────────────────────────────────────                    ║
║                                                                       ║
║  Trigger: "@Andy /export-session для глибокого аналізу"               ║
║  │                                                                    ║
║  ▼                                                                    ║
║  NanoClaw генерує SESSION TRANSFER PACKAGE:                           ║
║  │                                                                    ║
║  │  session_transfer/                                                 ║
║  │  ├── transfer.md              ← ГОЛОВНИЙ ФАЙЛ                     ║
║  │  │   ├── Company Context (summary, ~500 tokens)                   ║
║  │  │   ├── Current Task (what, step N of M)                         ║
║  │  │   ├── Work Done (key findings)                                 ║
║  │  │   ├── Pending (what needs deep analysis)                       ║
║  │  │   ├── Key Decisions (з decisions.jsonl)                        ║
║  │  │   └── Return Instructions (як повернути результат)             ║
║  │  ├── context_bundle.md        ← Стиснутий контекст (~5K tokens)   ║
║  │  ├── work_artifacts/          ← Проміжні результати               ║
║  │  │   ├── research_1.md                                             ║
║  │  │   └── analysis_draft.md                                         ║
║  │  └── memory_snapshot.jsonl    ← Останні 20 фактів + 10 рішень    ║
║  │                                                                    ║
║  │  DELIVERY:                                                         ║
║  │  Option A (manual): sendDocument → owner → upload to Claude.ai    ║
║  │  Option B (auto):   MCP Google Drive → Claude.ai Project          ║
║  │  Option C (git):    git push → owner git pull → Claude.ai upload  ║
║  │                                                                    ║
║  ▼                                                                    ║
║  Owner працює в Claude.ai:                                            ║
║  │  → Upload transfer.md + context_bundle.md до Project              ║
║  │  → Claude.ai має Extended Thinking, Artifacts, Web Search          ║
║  │  → Глибокий аналіз у 200K контексті                               ║
║  │  → Результат: analysis.md або artifact                            ║
║  │                                                                    ║
║  ▼                                                                    ║
║  RETURN: "@Andy /import-analysis" + прикріплений файл                ║
║  │                                                                    ║
║  │  NanoClaw:                                                         ║
║  │  ├── Отримує файл через Telegram                                   ║
║  │  ├── Спавнить контейнер для ІНТЕРПРЕТАЦІЇ                         ║
║  │  │   (meta/extraction/document-analyzer skill)                    ║
║  │  ├── Claude аналізує: що нового? які рішення?                      ║
║  │  ├── Оновлює (→ Flow G):                                          ║
║  │  │   ├── memory/CLAUDE.md (нові факти)                             ║
║  │  │   ├── memory/facts.jsonl (extracted facts)                     ║
║  │  │   ├── memory/decisions.jsonl (key decisions)                   ║
║  │  │   └── context/*.md (якщо стратегічні зміни)                    ║
║  │  └── Підтверджує: "✅ Імпортовано. 12 фактів, 3 рішення.         ║
║  │       Продовжую з кроку 4."                                        ║
║  ▼                                                                    ║
║  Робота продовжується в NanoClaw                                     ║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  TRANSFER TYPE 2: NANOCLAW ↔ CLAUDE CODE                             ║
║  (Для: створення скілів, дебаг, технічна робота)                     ║
║  ──────────────────────────────────────────────                       ║
║                                                                       ║
║  Спільний Canonical Store (Git repo).                                 ║
║  Claude Code працює напряму з тими ж файлами.                        ║
║                                                                       ║
║  SYNC FLOW:                                                           ║
║                                                                       ║
║  Claude Code (local)                    NanoClaw (VPS)                ║
║  │                                      │                             ║
║  │  git push origin main                │                             ║
║  │  ────────────────────────────────►   │                             ║
║  │                                      │  git pull (auto, cron 1m)  ║
║  │                                      │  sync.sh → refresh mounts  ║
║  │                                      │                             ║
║  │                    NanoClaw agent     │                             ║
║  │                    бачить НОВІ скіли  │                             ║
║  │                    та оновлений       │                             ║
║  │                    контекст           │                             ║
║  │                                      │                             ║
║  │                                      │  git push (auto, post-run) ║
║  │  ◄────────────────────────────────   │                             ║
║  │  git pull                            │                             ║
║  │  Бачить оновлений memory             │                             ║
║  │                                      │                             ║
║                                                                       ║
║  Latency: ~1-5 хвилин (git sync interval)                            ║
║  Conflict resolution: Git merge (manual for context/, auto for memory/)║
║                                                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  TRANSFER TYPE 3: NANOCLAW → CLAUDE.AI (AUTO, DEEP RESEARCH)         ║
║  (Для: автоматичний handoff складних задач)                           ║
║  ──────────────────────────────────────────                           ║
║                                                                       ║
║  TRIGGER: Agent визначає що задача ПЕРЕВИЩУЄ можливості NanoClaw:    ║
║  ├── Потрібен контекст >50K tokens                                    ║
║  ├── Потрібні інтерактивні Artifacts                                  ║
║  ├── Потрібна тривала сесія з людиною (>30 хв діалогу)               ║
║  │                                                                    ║
║  Agent:                                                               ║
║  "⚠️ Ця задача потребує глибокого аналізу. Рекомендую перейти        ║
║   в Claude.ai для повноцінної сесії. Генерую transfer package..."    ║
║                                                                       ║
║  → Автоматично генерує session_transfer/                              ║
║  → Відправляє owner'у через sendDocument                              ║
║  → Зберігає стан: "awaiting_external_result"                         ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

### 4.4 FLOW C: AGENT → AGENT (Handoff)

```
Flow C — передача роботи від одного skill-агента до іншого.
Handoff може бути INTRA-SESSION (sub-agents) або INTER-SESSION (IPC).

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  HANDOFF CONTRACT (JSON):                                          ║
║  ────────────────────────                                          ║
║                                                                    ║
║  {                                                                 ║
║    "id": "hoff_{timestamp}_{seq}",                                 ║
║    "type": "sequential" | "parallel" | "callback",                 ║
║                                                                    ║
║    "from": {                                                       ║
║      "skill": "marketing/market-intelligence/analyst",             ║
║      "company": "yakomanda",                                       ║
║      "runtime": "nanoclaw",                                        ║
║      "session_id": "sess_abc123"                                   ║
║    },                                                              ║
║                                                                    ║
║    "to": {                                                         ║
║      "skill": "marketing/positioning/strategist",                  ║
║      "company": "yakomanda",                                       ║
║      "runtime": null  ← будь-який доступний                       ║
║    },                                                              ║
║                                                                    ║
║    "payload": {                                                    ║
║      "content": "[analysis result markdown]",                      ║
║      "content_tokens": 2400,                                       ║
║      "confidence": 0.85,                                           ║
║      "evidence_grade": "IV",                                       ║
║      "gaps": ["pricing data incomplete"],                          ║
║      "sources": ["web search", "competitor websites"],             ║
║      "format": "analytical_report",                                ║
║      "attachments": ["research_report.md"]                         ║
║    },                                                              ║
║                                                                    ║
║    "constraints": {                                                ║
║      "tone_isolation": true,    ← не переносити tone з from       ║
║      "max_context_tokens": 4000,← обмеження для to-agent          ║
║      "requires_hitl": false,    ← потребує approval owner         ║
║      "deadline": "2026-02-28T15:00:00Z"                            ║
║    },                                                              ║
║                                                                    ║
║    "metadata": {                                                   ║
║      "created_at": "2026-02-28T14:30:00Z",                        ║
║      "ttl_hours": 24,           ← auto-expire                    ║
║      "chain_id": "pipeline_001",← пов'язує steps у pipeline      ║
║      "step": 1,                                                    ║
║      "total_steps": 6                                              ║
║    }                                                               ║
║  }                                                                 ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ТИП A: INTRA-SESSION (sub-agents, один контейнер)                ║
║  ─────────────────────────────────────────────────                 ║
║                                                                    ║
║  Orchestrator (main agent)                                         ║
║  │                                                                 ║
║  │  Claude Agent SDK → spawn sub-agent:                            ║
║  │  {                                                              ║
║  │    role: "research assistant",                                  ║
║  │    instructions: SKILL.md content,                              ║
║  │    tools: [subset of parent tools],                             ║
║  │    context: handoff.payload.content                             ║
║  │  }                                                              ║
║  │                                                                 ║
║  │  Sub-agent виконує → result повертається orchestrator'у          ║
║  │  Latency: мілісекунди (in-process)                              ║
║  │  Ізоляція: ТІЛЬКИ логічна (same container)                     ║
║  │  Коли: швидкі, прості handoffs (classification, formatting)    ║
║  │                                                                 ║
║  ├──────────────────────────────────────────────────────────────  ║
║  │                                                                 ║
║  ТИП B: INTER-SESSION (IPC filesystem, новий контейнер)           ║
║  ─────────────────────────────────────────────────────             ║
║  │                                                                 ║
║  │  Agent A (контейнер 1):                                        ║
║  │    → writes handoff JSON → /ipc/handoffs/hoff_001.json         ║
║  │    → exits                                                      ║
║  │                                                                 ║
║  │  IPC Watcher (хост, кожну 1 сек):                              ║
║  │    → reads /ipc/handoffs/hoff_001.json                         ║
║  │    → validates: company match, skill exists, constraints OK     ║
║  │    → spawns new container for "to" skill                       ║
║  │    → passes handoff as input                                    ║
║  │                                                                 ║
║  │  Agent B (контейнер 2):                                        ║
║  │    → reads handoff payload as initial context                  ║
║  │    → executes skill with handoff data                           ║
║  │    → writes result (or next handoff)                            ║
║  │                                                                 ║
║  │  Latency: 2-10 секунд (container spawn + SDK init)             ║
║  │  Ізоляція: ПОВНА (hypervisor/cgroups)                          ║
║  │  Коли: складні handoffs, різні security contexts               ║
║  │                                                                 ║
║  ├──────────────────────────────────────────────────────────────  ║
║  │                                                                 ║
║  ТИП C: CROSS-RUNTIME (через Git)                                 ║
║  ─────────────────────────────────                                 ║
║  │                                                                 ║
║  │  Agent A (NanoClaw):                                            ║
║  │    → writes handoff → companies/yakomanda/handoffs/             ║
║  │    → git push (auto, post-run)                                  ║
║  │                                                                 ║
║  │  Git sync interval: ~1-5 хвилин                                 ║
║  │                                                                 ║
║  │  Agent B (Claude Code або Claude.ai):                           ║
║  │    → git pull (auto або manual)                                 ║
║  │    → reads handoff                                              ║
║  │    → executes task                                              ║
║  │    → writes result → git push                                   ║
║  │                                                                 ║
║  │  Latency: 2-10 хвилин (git sync)                               ║
║  │  Коли: задача потребує іншого runtime                           ║
║  │                                                                 ║
╚══════════════════════════════════════════════════════════════════╝

HANDOFF VALIDATION RULES:
  ① company match: from.company === to.company (завжди)
  ② skill exists: to.skill registered в skills/
  ③ payload size: content_tokens ≤ max_context_tokens
  ④ TTL check: created_at + ttl_hours > now
  ⑤ chain integrity: step === expected_step for chain_id
  ⑥ HITL gate: якщо requires_hitl → Flow E перед доставкою
```

---

### 4.5 FLOW D: MULTI-AGENT PIPELINE (Orchestrated Process)

```
Flow D — це послідовність Flow C handoffs, керована orchestrator'ом.
Це НАЙСКЛАДНІШИЙ потік NanoClaw.

ПРИКЛАД: Content Pipeline (article creation)

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  TRIGGER: "@Andy напиши статтю про AI в маркетингу"                ║
║  ORCHESTRATOR: meta/orchestration/content-pipeline                 ║
║  PROCESS TEMPLATE: foundation/process_templates/content_pipeline.md║
║                                                                    ║
║  ┌──────────────────────────────────────────────────────────────┐ ║
║  │                                                                │ ║
║  │  STEP 1: RESEARCH                                              │ ║
║  │  Skill: marketing/content/topic-researcher                     │ ║
║  │  Input: topic + context/market/intelligence.md                 │ ║
║  │  Output: research_report (markdown)                            │ ║
║  │  Gate: confidence > 0.6                                        │ ║
║  │  Type: INTRA-SESSION sub-agent                                 │ ║
║  │  ✅ Result: 0.78 confidence, 1800 tokens                      │ ║
║  │                                                                │ ║
║  │  STEP 2: SEO ANALYSIS                                          │ ║
║  │  Skill: marketing/geo-aeo/seo-analyst                          │ ║
║  │  Input: topic + research + context/market/channels.md          │ ║
║  │  Output: seo_brief                                             │ ║
║  │  Gate: keywords_found ≥ 5                                      │ ║
║  │  Type: INTRA-SESSION sub-agent                                 │ ║
║  │  ✅ Result: 12 keywords found                                  │ ║
║  │                                                                │ ║
║  │  STEP 3: OUTLINE                                               │ ║
║  │  Skill: marketing/content/outline-architect                    │ ║
║  │  Input: research + seo_brief                                   │ ║
║  │  Output: content_outline                                       │ ║
║  │  Gate: sections ≥ 3                                            │ ║
║  │  Type: INTRA-SESSION sub-agent                                 │ ║
║  │  ✅ Result: 5 sections                                         │ ║
║  │                                                                │ ║
║  │  ★ HITL GATE (→ Flow E)                                        │ ║
║  │  "📋 Outline готовий (5 секцій). Затвердити?"                  │ ║
║  │  [✅ Так] [✏️ Правки] [❌ Скасувати]                           │ ║
║  │  Timeout: 15 хв → нагадування ×2 → safe default (proceed)     │ ║
║  │  ✅ User approved                                               │ ║
║  │                                                                │ ║
║  │  STEP 4: WRITING                                               │ ║
║  │  Skill: marketing/content/copywriter                           │ ║
║  │  Input: outline + context/brand/voice.md + context/audience/   │ ║
║  │  Output: article_draft                                         │ ║
║  │  Gate: word_count > 1500                                       │ ║
║  │  Type: INTER-SESSION (new container — heavy task)              │ ║
║  │  Model: Opus 4.6 (quality writing needs best model)            │ ║
║  │  ✅ Result: 2,400 words                                        │ ║
║  │                                                                │ ║
║  │  STEP 5: EDITING                                               │ ║
║  │  Skill: marketing/content/editor                               │ ║
║  │  Input: draft + context/brand/guidelines.md                    │ ║
║  │  Output: polished_article                                      │ ║
║  │  Gate: quality_score > 80                                      │ ║
║  │  Type: INTER-SESSION (fresh perspective, no context bleed)     │ ║
║  │  ✅ Result: 87/100                                              │ ║
║  │                                                                │ ║
║  │  STEP 6: REPURPOSING                                           │ ║
║  │  Skill: communication/social-media/repurposer                  │ ║
║  │  Input: article + context/market/channels.md                   │ ║
║  │  Outputs:                                                      │ ║
║  │  ├── telegram_post  (via channel_adaptors/telegram.md)         │ ║
║  │  ├── linkedin_post  (via channel_adaptors/linkedin.md)         │ ║
║  │  └── newsletter     (via channel_adaptors/email.md)            │ ║
║  │  Type: INTRA-SESSION (multiple outputs, same context)          │ ║
║  │  ✅ Result: 3 formats generated                                 │ ║
║  │                                                                │ ║
║  │  POST-PIPELINE:                                                │ ║
║  │  ├── Send results to user (Telegram message + documents)       │ ║
║  │  ├── → Flow G: update memory                                   │ ║
║  │  │   ├── CLAUDE.md: "article about AI marketing completed"     │ ║
║  │  │   ├── facts.jsonl: key findings from research               │ ║
║  │  │   └── decisions.jsonl: "style: practical, tone: expert"     │ ║
║  │  └── → Flow J: log total cost ($0.35 — 6 agent invocations)   │ ║
║  │                                                                │ ║
║  └──────────────────────────────────────────────────────────────┘ ║
║                                                                    ║
║  FAILURE HANDLING:                                                 ║
║  ├── Gate FAIL: retry 1x → if still fails → HITL ("не пройшов    ║
║  │   gate, змінити параметри?") → adjust & retry OR abort         ║
║  ├── Agent CRASH: handoff has chain_id → resume from last step    ║
║  ├── Timeout (per step): 10 хв default → alert → abort pipeline  ║
║  └── User CANCEL (HITL): cleanup temp files, log cancellation    ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝

PROCESS TEMPLATE FORMAT (foundation/process_templates/content_pipeline.md):

  # Content Pipeline
  ## Trigger: /write-article, /create-post, implicit "напиши статтю"
  ## Steps:
  1. topic-researcher    | gate: confidence>0.6    | type: sub-agent
  2. seo-analyst         | gate: keywords≥5        | type: sub-agent
  3. outline-architect   | gate: sections≥3        | type: sub-agent
  4. HITL                | type: approval           | timeout: 15m
  5. copywriter          | gate: words>1500         | type: container
  6. editor              | gate: quality>80         | type: container
  7. repurposer          | outputs: 3               | type: sub-agent
  ## Model defaults: steps 1-3,7=Sonnet, steps 5-6=Opus
  ## Estimated cost: $0.25-0.50
  ## Estimated time: 5-15 minutes
```

---

### 4.6 FLOW E: HITL CONVENTION (Human-in-the-Loop)

```
HITL — це НЕ окремий механізм, а КОНВЕНЦІЯ поверх існуючих
IPC та Telegram messaging. Будь-який агент може запросити
рішення owner'а в будь-який момент.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  HITL REQUEST (agent → owner):                                     ║
║  ──────────────────────────────                                    ║
║                                                                    ║
║  Agent (всередині контейнера):                                     ║
║  │                                                                 ║
║  │  IPC tool: request_hitl({                                       ║
║  │    type: "approval" | "choice" | "input" | "review",            ║
║  │    prompt: "📋 Outline готовий (5 секцій). Затвердити?",        ║
║  │    options: [                                                   ║
║  │      { id: "approve", label: "✅ Так", is_default: true },      ║
║  │      { id: "edit",    label: "✏️ Правки" },                     ║
║  │      { id: "cancel",  label: "❌ Скасувати" }                   ║
║  │    ],                                                           ║
║  │    context: "[outline preview, max 2000 chars]",                ║
║  │    timeout_minutes: 15,                                         ║
║  │    safe_default: "approve"   ← що робити при timeout            ║
║  │  })                                                             ║
║  │                                                                 ║
║  │  Agent ПАУЗИТЬСЯ. Чекає на response.                            ║
║  ▼                                                                 ║
║                                                                    ║
║  IPC Watcher (хост):                                               ║
║  │  Знаходить файл /ipc/{group}/hitl/hitl_{id}.json                ║
║  │                                                                 ║
║  │  Конвертує у Telegram INLINE KEYBOARD:                          ║
║  │                                                                 ║
║  │  sendMessage(chat_id, text, {                                   ║
║  │    reply_markup: {                                              ║
║  │      inline_keyboard: [[                                        ║
║  │        { text: "✅ Так",      callback_data: "hitl_{id}_approve"},║
║  │        { text: "✏️ Правки",   callback_data: "hitl_{id}_edit"  },║
║  │        { text: "❌ Скасувати", callback_data: "hitl_{id}_cancel"}║
║  │      ]]                                                         ║
║  │    }                                                            ║
║  │  })                                                             ║
║  ▼                                                                 ║
║                                                                    ║
║  TELEGRAM (owner бачить):                                          ║
║  ┌─────────────────────────────────────────────┐                  ║
║  │ 📋 Outline готовий (5 секцій). Затвердити?  │                  ║
║  │                                              │                  ║
║  │ [context preview, collapsed]                 │                  ║
║  │                                              │                  ║
║  │ [✅ Так]  [✏️ Правки]  [❌ Скасувати]        │                  ║
║  └─────────────────────────────────────────────┘                  ║
║                                                                    ║
║  Owner натискає кнопку → Telegram CallbackQuery:                   ║
║  │                                                                 ║
║  │  telegram.ts:                                                   ║
║  │    answerCallbackQuery(callback_query_id)                       ║
║  │    editMessageReplyMarkup(chat_id, msg_id, null) ← видалити кн. ║
║  │    parse callback_data: hitl_{id}_{choice}                      ║
║  │                                                                 ║
║  │  Записує відповідь:                                             ║
║  │    /ipc/{group}/hitl/hitl_{id}_response.json                    ║
║  │    { choice: "approve", timestamp, user_input: null }           ║
║  │                                                                 ║
║  ▼                                                                 ║
║  Agent (контейнер) ПРОДОВЖУЄТЬСЯ:                                  ║
║  │  Reads response via IPC tool polling                             ║
║  │  choice === "approve" → proceed to next step                    ║
║  │  choice === "edit" → request_hitl(type="input", ...) → wait     ║
║  │  choice === "cancel" → abort pipeline, cleanup                  ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  TIMEOUT PROTOCOL:                                                 ║
║  ─────────────────                                                 ║
║                                                                    ║
║  T+0:    HITL request sent to Telegram                             ║
║  T+10m:  Reminder #1: "⏰ Чекаю на ваше рішення..."               ║
║  T+14m:  Reminder #2: "⏰ Останнє нагадування. Автовибір через 1хв"║
║  T+15m:  TIMEOUT → safe_default applied                            ║
║          editMessage: "⏰ Timeout. Обрано: ✅ Так (за замовч.)"     ║
║                                                                    ║
║  ВАЖЛИВО: safe_default ЗАВЖДИ має бути безпечним:                  ║
║  ├── approval → "approve" (продовжити)                             ║
║  ├── destructive action → "cancel" (не виконувати)                 ║
║  └── publish → "save_draft" (зберегти, не публікувати)             ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  HITL TYPES:                                                       ║
║  ────────────                                                      ║
║                                                                    ║
║  1. APPROVAL: Так/Ні (найчастіше)                                 ║
║     → Inline keyboard з 2-3 кнопками                               ║
║     → Для: затвердження outline, draft, publish                   ║
║                                                                    ║
║  2. CHOICE: Вибір з варіантів                                      ║
║     → Inline keyboard з 3-5 кнопками                               ║
║     → Для: вибір стилю, тону, target audience                    ║
║                                                                    ║
║  3. INPUT: Вільний текст від owner'а                               ║
║     → Message prompt + wait for next message                       ║
║     → Для: правки, коментарі, додаткові інструкції                ║
║                                                                    ║
║  4. REVIEW: Перегляд документа + feedback                          ║
║     → sendDocument + inline keyboard                               ║
║     → Для: фінальний review перед публікацією                     ║
║                                                                    ║
║  5. ESCALATION: Агент не впевнений, запитує guidance               ║
║     → Detailed message + "що робити далі?"                        ║
║     → Для: conflict resolution, ambiguous instructions             ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝

HITL AUDIT TRAIL:
  Кожна HITL взаємодія записується в decisions.jsonl:
  {
    "type": "hitl",
    "hitl_type": "approval",
    "prompt": "Outline ready?",
    "choice": "approve",
    "user": "god",
    "timestamp": "2026-02-28T14:35:00Z",
    "chain_id": "pipeline_001",
    "step": 4
  }
```

---

### 4.7 FLOW F: SCHEDULED TASKS

```
Flow F — автономне виконання задач за розкладом.
Три типи: cron, interval, once.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  CREATION: Agent → IPC → scheduler                                ║
║  ─────────────────────────────────                                 ║
║                                                                    ║
║  User: "@Andy надсилай мені новинну зведення щопонеділка о 8:00"  ║
║  │                                                                 ║
║  │  Agent (контейнер):                                             ║
║  │  → schedule_task({                                              ║
║  │      group_id: "yakomanda",                                     ║
║  │      schedule_type: "cron",                                     ║
║  │      schedule_value: "0 8 * * 1",    ← Пн о 8:00               ║
║  │      skill: "marketing/content/news-curator",                   ║
║  │      prompt: "Підготуй тижневу зведення новин AI-маркетингу",  ║
║  │      model: "sonnet",                                           ║
║  │      notify: true                    ← відправити результат    ║
║  │    })                                                           ║
║  │  → writes JSON → /ipc/{group}/tasks/                            ║
║  │                                                                 ║
║  ▼                                                                 ║
║  IPC Watcher (хост):                                               ║
║  │  → reads task JSON                                               ║
║  │  → validates: group registered, skill exists                    ║
║  │  → task-scheduler.ts → INSERT INTO scheduled_tasks              ║
║  │                                                                 ║
║  │  SQLite row:                                                    ║
║  │  ┌───────────────┬─────────────────────────────────────┐       ║
║  │  │ id             │ AUTO                                 │       ║
║  │  │ group_id       │ "yakomanda"                          │       ║
║  │  │ schedule_type  │ "cron"                               │       ║
║  │  │ schedule_value │ "0 8 * * 1"                          │       ║
║  │  │ skill          │ "marketing/content/news-curator"     │       ║
║  │  │ prompt         │ "Підготуй тижневу зведення..."       │       ║
║  │  │ model          │ "sonnet"                              │       ║
║  │  │ notify         │ 1                                     │       ║
║  │  │ next_run_at    │ 2026-03-02T08:00:00Z                 │       ║
║  │  │ last_run_at    │ null                                  │       ║
║  │  │ status         │ "active"                              │       ║
║  │  │ created_at     │ 2026-02-28T14:30:00Z                 │       ║
║  │  └───────────────┴─────────────────────────────────────┘       ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  EXECUTION: scheduler → container → result                         ║
║  ─────────────────────────────────────────                         ║
║                                                                    ║
║  startScheduler() — кожні 60 секунд:                               ║
║  │                                                                 ║
║  │  getDueTasks():                                                 ║
║  │    SELECT * FROM scheduled_tasks                                 ║
║  │    WHERE status='active' AND next_run_at <= NOW()                ║
║  │                                                                 ║
║  │  Для кожної due task:                                           ║
║  │  ├── Spawn container (як Flow A, етап 3)                        ║
║  │  │   Company context + skill + memory = same mounts             ║
║  │  │   Prompt = task.prompt                                        ║
║  │  │   Model = task.model                                          ║
║  │  │                                                              ║
║  │  ├── Виконання (як Flow A, етап 4)                              ║
║  │  │   Agent generates output                                     ║
║  │  │                                                              ║
║  │  ├── Delivery:                                                  ║
║  │  │   if notify=true → send result to group chat                 ║
║  │  │   if notify=false → save to files only                       ║
║  │  │                                                              ║
║  │  ├── Post-run:                                                  ║
║  │  │   → Flow G (memory update)                                    ║
║  │  │   → Flow J (cost logging)                                     ║
║  │  │                                                              ║
║  │  └── Schedule next:                                              ║
║  │      cron → calculate next_run_at from cron expression          ║
║  │      interval → next_run_at = NOW() + interval_ms               ║
║  │      once → status = "completed"                                 ║
║  │                                                                 ║
║  ▼                                                                 ║
║  UPDATE scheduled_tasks SET                                        ║
║    last_run_at = NOW(),                                             ║
║    next_run_at = [calculated],                                      ║
║    run_count = run_count + 1                                        ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  MANAGEMENT COMMANDS:                                              ║
║  ────────────────────                                              ║
║                                                                    ║
║  "@Andy /tasks"          → list all active tasks                   ║
║  "@Andy /task-pause 5"   → pause task #5                           ║
║  "@Andy /task-resume 5"  → resume task #5                          ║
║  "@Andy /task-delete 5"  → delete task #5                          ║
║  "@Andy /task-run 5"     → run task #5 NOW (one-off)               ║
║                                                                    ║
║  SECURITY:                                                         ║
║  Main group: може створювати tasks для БУДЬ-ЯКОЇ групи             ║
║  Non-main: може створювати tasks ТІЛЬКИ для СВОЄЇ групи            ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### 4.8 FLOW G: MEMORY LIFECYCLE (3-рівнева архітектура)

```
Flow G — найважливіший "фоновий" потік NanoClaw.
Працює ПІСЛЯ КОЖНОГО agent execution (95%+ усіх flows).
Це те, що робить NanoClaw РОЗУМНІШИМ з часом.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  3-РІВНЕВА MEMORY ARCHITECTURE                                    ║
║  ═══════════════════════════════                                   ║
║                                                                    ║
║  ┌──────────────────────────────────────────────────────────────┐ ║
║  │                                                                │ ║
║  │  РІВЕНЬ 1: CLAUDE.md (Identity + Recent Memory)                │ ║
║  │  ──────────────────────────────────────────────                 │ ║
║  │                                                                │ ║
║  │  Файл: companies/{name}/memory/CLAUDE.md                       │ ║
║  │  Формат: Markdown                                              │ ║
║  │  Розмір: 500-2000 tokens (controlled)                          │ ║
║  │  Читається: КОЖНУ СЕСІЮ (частина system prompt, Layer 3)       │ ║
║  │  Записується: КОЖНУ СЕСІЮ (post-run hook)                     │ ║
║  │  Видимість: людина може читати та редагувати                   │ ║
║  │                                                                │ ║
║  │  СТРУКТУРА:                                                    │ ║
║  │  ```markdown                                                   │ ║
║  │  # ЯКоманда — Memory                                          │ ║
║  │                                                                │ ║
║  │  ## Identity Snapshot                                          │ ║
║  │  AI-освітня платформа. Курси $490-990. ЦА: фрілансери та      │ ║
║  │  підприємці $500-5000/місяць. Місія: маркетингова              │ ║
║  │  суверенність через AI.                                        │ ║
║  │                                                                │ ║
║  │  ## Current Priorities                                         │ ║
║  │  1. Запуск першого модуля курсу (дедлайн: 15 березня)         │ ║
║  │  2. Content pipeline для Telegram-каналу                       │ ║
║  │  3. Конкурентний аналіз оновлення                              │ ║
║  │                                                                │ ║
║  │  ## Recent Activity (last 10)                                  │ ║
║  │  - 2026-02-28: проаналізовано 5 конкурентів                   │ ║
║  │  - 2026-02-27: написано статтю про AI в маркетингу            │ ║
║  │  - 2026-02-26: оновлено pricing стратегію                     │ ║
║  │  ...                                                           │ ║
║  │                                                                │ ║
║  │  ## Key Decisions                                              │ ║
║  │  - Tone: практичний експерт, без buzzwords                    │ ║
║  │  - Pricing: $490 basic, $990 premium                           │ ║
║  │  - Platform: Telegram first, LinkedIn second                   │ ║
║  │                                                                │ ║
║  │  ## Owner Preferences                                          │ ║
║  │  - Завжди evidence-graded (MECE methodology)                  │ ║
║  │  - Українська мова для контенту                                │ ║
║  │  - Перевагу конкретним цифрам, не загальним твердженням       │ ║
║  │  ```                                                           │ ║
║  │                                                                │ ║
║  │  ROTATION: коли >50 записів у Recent Activity:                 │ ║
║  │  ├── Найстаріші 25 → MIGRATE to facts.jsonl                   │ ║
║  │  ├── Key Decisions → зберігаються завжди                       │ ║
║  │  └── CLAUDE.md залишається compact (≤2000 tokens)              │ ║
║  │                                                                │ ║
║  ├──────────────────────────────────────────────────────────────┤ ║
║  │                                                                │ ║
║  │  РІВЕНЬ 2: facts.jsonl (Structured Long-term Facts)            │ ║
║  │  ──────────────────────────────────────────────                 │ ║
║  │                                                                │ ║
║  │  Файл: companies/{name}/memory/facts.jsonl                     │ ║
║  │  Формат: JSON Lines (один об'єкт на рядок)                    │ ║
║  │  Розмір: необмежений (append-only)                             │ ║
║  │  Читається: ВИБІРКОВО (topic-relevant через grep/search)       │ ║
║  │  Записується: post-run extraction                              │ ║
║  │                                                                │ ║
║  │  SCHEMA:                                                       │ ║
║  │  {                                                             │ ║
║  │    "id": "fact_20260228_001",                                  │ ║
║  │    "timestamp": "2026-02-28T14:30:00Z",                        │ ║
║  │    "domain": "marketing",         ← для filtering              │ ║
║  │    "topic": "competitors",        ← для search                 │ ║
║  │    "fact": "Projector Institute charges $300-800 per course",  │ ║
║  │    "source": "web_search",        ← provenance                 │ ║
║  │    "confidence": 0.85,                                         │ ║
║  │    "evidence_grade": "IV",                                     │ ║
║  │    "expires": null,               ← null=permanent             │ ║
║  │    "related_to": ["pricing", "competitors", "projector"],      │ ║
║  │    "extracted_by": "marketing/market-intelligence/analyst"     │ ║
║  │  }                                                             │ ║
║  │                                                                │ ║
║  │  RETRIEVAL (при побудові system prompt):                       │ ║
║  │  Agent-runner:                                                 │ ║
║  │    1. Parse user query → extract keywords                       │ ║
║  │    2. grep -i "keyword" facts.jsonl                             │ ║
║  │    3. Sort by relevance (topic match + recency)                │ ║
║  │    4. Take top 20 facts → include in Layer 3 prompt            │ ║
║  │    5. Total tokens ≤ 1500 for facts section                    │ ║
║  │                                                                │ ║
║  │  MAINTENANCE:                                                  │ ║
║  │  ├── Deduplication: щомісяця, merge similar facts              │ ║
║  │  ├── Expiry: видалити facts де expires < NOW()                  │ ║
║  │  ├── Compaction: >1000 facts → archive old → compress          │ ║
║  │  └── Backup: git commit → canonical store                      │ ║
║  │                                                                │ ║
║  ├──────────────────────────────────────────────────────────────┤ ║
║  │                                                                │ ║
║  │  РІВЕНЬ 3: decisions.jsonl (Decision Log)                      │ ║
║  │  ──────────────────────────────────────────                    │ ║
║  │                                                                │ ║
║  │  Файл: companies/{name}/memory/decisions.jsonl                 │ ║
║  │  Формат: JSON Lines                                            │ ║
║  │  Розмір: append-only (рідше ніж facts)                         │ ║
║  │  Читається: останні 10 рішень ЗАВЖДИ в system prompt           │ ║
║  │  Записується: коли агент або owner приймає стратегічне рішення │ ║
║  │                                                                │ ║
║  │  SCHEMA:                                                       │ ║
║  │  {                                                             │ ║
║  │    "id": "dec_20260228_001",                                   │ ║
║  │    "timestamp": "2026-02-28T14:30:00Z",                        │ ║
║  │    "type": "strategic" | "tactical" | "hitl" | "preference",   │ ║
║  │    "domain": "marketing",                                      │ ║
║  │    "decision": "Use practical expert tone, avoid buzzwords",   │ ║
║  │    "rationale": "Owner prefers evidence-based approach",       │ ║
║  │    "made_by": "owner" | "agent" | "hitl",                      │ ║
║  │    "reversible": true,                                         │ ║
║  │    "affects": ["content", "brand_voice", "all_skills"],        │ ║
║  │    "supersedes": null | "dec_20260215_003"                      │ ║
║  │  }                                                             │ ║
║  │                                                                │ ║
║  │  МЕТА: Агент НІКОЛИ не перепитує вже прийняті рішення.        │ ║
║  │  Якщо decision є — агент слідує. Якщо конфлікт — запитує HITL. │ ║
║  │                                                                │ ║
║  └──────────────────────────────────────────────────────────────┘ ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  MEMORY UPDATE FLOW (post-run hook, КОЖЕН запуск):                ║
║  ──────────────────────────────────────────────────                ║
║                                                                    ║
║  Agent завершив execution:                                         ║
║  │                                                                 ║
║  │  ① EXTRACT (agent самостійно визначає що зберегти):            ║
║  │     ├── Нові факти → facts.jsonl (append)                      ║
║  │     ├── Стратегічні рішення → decisions.jsonl (append)         ║
║  │     └── Оновлення статусу → CLAUDE.md Recent Activity           ║
║  │                                                                 ║
║  │  ② CLAUDE.MD UPDATE RULES:                                     ║
║  │     ├── Append до Recent Activity (top of list)                ║
║  │     ├── Якщо >50 items → migrate oldest 25 to facts.jsonl     ║
║  │     ├── Якщо Key Decision changed → update in place             ║
║  │     ├── Якщо Current Priority completed → remove                ║
║  │     └── НІКОЛИ не перезаписуй весь файл — тільки sections      ║
║  │                                                                 ║
║  │  ③ VALIDATION:                                                  ║
║  │     ├── facts.jsonl: valid JSON per line                        ║
║  │     ├── decisions.jsonl: valid JSON per line                    ║
║  │     ├── CLAUDE.md: valid markdown, ≤2000 tokens                ║
║  │     └── No PII leakage (email, phone, passwords)               ║
║  │                                                                 ║
║  │  ④ GIT COMMIT (async, не блокує response):                     ║
║  │     git add memory/ && git commit -m "memory: [summary]"       ║
║  │     git push (якщо auto-push enabled)                           ║
║  │                                                                 ║
║  ▼                                                                 ║
║  Memory updated. Наступна сесія побачить нові дані.                ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝

MEMORY ACROSS RUNTIMES:

  NanoClaw (VPS):
    → Reads/writes memory/ напряму (mounted)
    → Git push після кожного оновлення

  Claude Code (local):
    → git pull → бачить актуальний memory/
    → git push → NanoClaw sync.sh → mount refresh

  Claude.ai:
    → Manual: session_transfer.md містить memory snapshot
    → Return: /import-analysis → agent extracts → updates memory
    → Future: MCP Google Drive → auto sync

  CONFLICT RESOLUTION:
    ├── facts.jsonl: append-only → no conflicts possible
    ├── decisions.jsonl: append-only → no conflicts possible
    └── CLAUDE.md: git merge (manual resolve if needed)
        Priority: NanoClaw > Claude Code > Claude.ai
```

---

### 4.9 FLOW H: CONTEXT EVOLUTION

```
Flow H — коли owner оновлює стратегічний контекст компанії.
Рідкий (~1% запусків), але критичний для консистентності.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  TRIGGER: Owner змінює стратегію, аудиторію, pricing, тощо.       ║
║                                                                    ║
║  METHOD 1: Chat command                                            ║
║  "@Andy /update-context pricing: змінити на $690 замість $490"    ║
║  │                                                                 ║
║  │  Agent (meta/extraction/context-compiler):                      ║
║  │  ├── Parse command                                              ║
║  │  ├── Identify target: context/product/pricing.md                ║
║  │  ├── HITL: "Оновити pricing.md: $490→$690?"                    ║
║  │  │   [✅ Так] [✏️ Показати diff] [❌ Скасувати]                 ║
║  │  ├── Apply change                                               ║
║  │  ├── Log decision: decisions.jsonl                              ║
║  │  └── Git commit + push                                          ║
║  │                                                                 ║
║  METHOD 2: File upload                                             ║
║  Owner прикріплює оновлений PDF/DOCX → "@Andy /update-context"   ║
║  │                                                                 ║
║  │  Agent (meta/extraction/document-analyzer):                     ║
║  │  ├── Extract changes from document                              ║
║  │  ├── Identify affected context files                            ║
║  │  ├── HITL: show proposed changes                                ║
║  │  ├── Apply changes                                              ║
║  │  └── Git commit + push                                          ║
║  │                                                                 ║
║  METHOD 3: Context Interview                                       ║
║  "@Andy /interview" → structured Q&A для побудови контексту        ║
║  │                                                                 ║
║  │  Agent (meta/extraction/context-interviewer):                   ║
║  │  ├── Послідовні питання по кожній context area                  ║
║  │  ├── Валідація відповідей                                       ║
║  │  ├── Генерація context files                                    ║
║  │  ├── HITL: review generated files                               ║
║  │  └── Save + git commit                                          ║
║  │                                                                 ║
║  POST-UPDATE PROPAGATION:                                          ║
║  │                                                                 ║
║  │  ① NanoClaw: наступний container автоматично бачить нові дані  ║
║  │     (mount refresh при sync.sh)                                 ║
║  │  ② Claude Code: git pull → бачить зміни                        ║
║  │  ③ Claude.ai: потребує manual re-upload                         ║
║  │  ④ Prompt cache: INVALIDATED (Layer 2 змінився)                 ║
║  │     → наступний запит перебудує кеш                              ║
║  │  ⑤ Memory: decisions.jsonl отримує запис про зміну              ║
║  │                                                                 ║
║  CONTEXT FILE HIERARCHY:                                           ║
║  context/                                                          ║
║  ├── company/identity.md      ← ЯК рідко (раз на рік)            ║
║  ├── company/team.md          ← ЯК рідко                         ║
║  ├── company/operations.md    ← ЯК рідко                         ║
║  ├── product/spec.md          ← СЕРЕДНЬО (раз на квартал)         ║
║  ├── product/pricing.md       ← СЕРЕДНЬО                         ║
║  ├── product/positioning.md   ← СЕРЕДНЬО                         ║
║  ├── audience/icp.md          ← СЕРЕДНЬО                         ║
║  ├── audience/jtbd.md         ← СЕРЕДНЬО                         ║
║  ├── audience/voc.md          ← ЧАСТО (раз на місяць, VoC mining) ║
║  ├── audience/awareness.md    ← СЕРЕДНЬО                         ║
║  ├── brand/voice.md           ← ЯК рідко                         ║
║  ├── brand/visual.md          ← ЯК рідко                         ║
║  ├── brand/guidelines.md      ← ЯК рідко                         ║
║  ├── market/intelligence.md   ← ЧАСТО (раз на місяць)             ║
║  ├── market/competitors.md    ← ЧАСТО                             ║
║  ├── market/channels.md       ← СЕРЕДНЬО                         ║
║  └── market/geo_aeo.md        ← ЧАСТО (AI landscape changes fast) ║
║                                                                    ║
║  IMMUTABLE: context/ files ніколи не видаляються автоматично.      ║
║  Тільки owner через explicit command або HITL approval.            ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### 4.10 FLOW I: BATCH PROCESSING

```
Flow I — масова генерація контенту через Claude Batch API.
Рідкий (<1% запусків), але критичний для масштабування.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  TRIGGER: "@Andy /batch-generate 30 постів для Telegram"          ║
║                                                                    ║
║  ORCHESTRATOR (хост-процес, НЕ контейнер):                        ║
║  │                                                                 ║
║  │  ① PREPARATION:                                                ║
║  │     ├── Load company context (for system prompt)                ║
║  │     ├── Load skill (content/social-media/telegram-poster)       ║
║  │     ├── Generate 30 unique prompts (topics from content plan)   ║
║  │     └── Build .jsonl batch file:                                ║
║  │         {"custom_id":"post_01","params":{"model":"sonnet",      ║
║  │          "system":"[cached context]","messages":[...]}}         ║
║  │         {"custom_id":"post_02","params":{...}}                  ║
║  │         ... ×30                                                  ║
║  │                                                                 ║
║  │  ② COST OPTIMIZATION:                                           ║
║  │     ├── Batch API: 50% discount ($1.5/MTok замість $3)          ║
║  │     ├── Prompt Caching: system prompt кешується                 ║
║  │     │   → 90% discount на повторювані частини                   ║
║  │     ├── Combined savings: ~95% vs individual requests           ║
║  │     │   30 posts × ~$0.05 each = ~$1.50 standard                ║
║  │     │   Batch + caching = ~$0.08 total                           ║
║  │     └── HITL: "Генерувати 30 постів? ~$0.08. Продовжити?"      ║
║  │                                                                 ║
║  │  ③ SUBMISSION:                                                  ║
║  │     POST /v1/messages/batches                                    ║
║  │     → batch_id: "batch_abc123"                                   ║
║  │     → status: "in_progress"                                      ║
║  │     → 24-hour processing window                                  ║
║  │                                                                 ║
║  │  ④ MONITORING (polling кожні 5 хв):                              ║
║  │     GET /v1/messages/batches/{batch_id}                          ║
║  │     → status: "in_progress" | "ended"                            ║
║  │     → Progress: "15/30 completed"                                ║
║  │     → Notify owner: "⏳ Batch 50% готовий (15/30)"              ║
║  │                                                                 ║
║  │  ⑤ RESULT PROCESSING:                                           ║
║  │     GET /v1/messages/batches/{batch_id}/results                  ║
║  │     → Download .jsonl results                                    ║
║  │     → Parse: extract each response                               ║
║  │     → Quality check: reject < threshold                          ║
║  │     → Format per channel_adaptors/telegram.md                    ║
║  │                                                                 ║
║  │  ⑥ DELIVERY:                                                    ║
║  │     ├── Option A: Send all to owner for review                  ║
║  │     ├── Option B: Schedule posting (1 per day)                   ║
║  │     │   → Creates 30 Flow F tasks (once, spread over 30 days)   ║
║  │     └── Option C: Save to files/ for manual use                  ║
║  │                                                                 ║
║  │  ⑦ POST-BATCH:                                                  ║
║  │     → Flow G: log generation metadata to facts.jsonl             ║
║  │     → Flow J: log batch cost                                     ║
║  │     → Notify: "✅ 30 постів готові. 28/30 пройшли quality check"║
║  │                                                                 ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### 4.11 FLOW J: COST TRACKING

```
Flow J працює ПАРАЛЕЛЬНО з кожним іншим flow.
Кожен API запит логується для бюджетного контролю.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  COST LOG (append to data/cost_log.jsonl):                         ║
║  ─────────────────────────────────────────                         ║
║                                                                    ║
║  {                                                                 ║
║    "timestamp": "2026-02-28T14:30:00Z",                            ║
║    "company": "yakomanda",                                         ║
║    "flow": "A",                                                    ║
║    "skill": "marketing/content/copywriter",                        ║
║    "model": "claude-sonnet-4-6",                                   ║
║    "input_tokens": 4500,                                           ║
║    "output_tokens": 2400,                                          ║
║    "cache_read_tokens": 3800,     ← cached portion                ║
║    "cache_write_tokens": 700,      ← new cache                    ║
║    "thinking_tokens": 1200,        ← Extended Thinking             ║
║    "cost_usd": 0.054,             ← calculated                    ║
║    "duration_ms": 12400,                                           ║
║    "batch": false,                                                 ║
║    "session_id": "sess_abc123"                                     ║
║  }                                                                 ║
║                                                                    ║
║  BUDGET MANAGEMENT:                                                ║
║  ──────────────────                                                ║
║                                                                    ║
║  Per-company budget (companies/{name}/memory/budget.json):         ║
║  {                                                                 ║
║    "monthly_limit_usd": 50.00,                                     ║
║    "daily_limit_usd": 5.00,                                        ║
║    "alert_threshold": 0.80,       ← alert at 80% usage            ║
║    "current_month": {                                              ║
║      "total_usd": 23.45,                                          ║
║      "by_model": {                                                 ║
║        "opus-4-6": 8.20,                                           ║
║        "sonnet-4-6": 12.10,                                        ║
║        "haiku-4-5": 3.15                                           ║
║      },                                                            ║
║      "by_flow": {                                                  ║
║        "A": 15.30,                                                 ║
║        "D": 5.60,                                                  ║
║        "F": 2.55                                                   ║
║      }                                                             ║
║    }                                                               ║
║  }                                                                 ║
║                                                                    ║
║  ALERTS:                                                           ║
║  ├── 80% budget → "⚠️ Використано 80% місячного бюджету ($40/$50)"║
║  ├── 95% budget → "🚨 Критично: 95% бюджету. Автоперехід на Haiku"║
║  ├── 100% budget → downgrade to Haiku-only mode                    ║
║  └── Owner override: "@Andy /budget-override +$20"                 ║
║                                                                    ║
║  MODEL DOWNGRADE CASCADE:                                          ║
║  Normal: Opus (complex) → Sonnet (standard) → Haiku (simple)     ║
║  80% budget: Sonnet → Haiku                                        ║
║  95% budget: Haiku only                                            ║
║  100% budget: pause non-essential, alert owner                     ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### 4.12 CHANNEL ADAPTORS: SPECIFICATIONS

```
Channel adaptors — це markdown-файли у foundation/channel_adaptors/
які визначають ПРАВИЛА ФОРМАТУВАННЯ для кожного каналу доставки.
Агент читає adaptor і форматує output відповідно.

КЛЮЧОВИЙ ПРИНЦИП: Skill генерує SEMANTIC content.
                   Adaptor конвертує у PLATFORM-SPECIFIC format.
                   Один skill → N adaptors = N platform outputs.

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  ADAPTOR 1: telegram.md                                            ║
║  ─────────────────────────                                         ║
║                                                                    ║
║  # Telegram Channel Adaptor                                        ║
║                                                                    ║
║  ## Format Rules                                                   ║
║  - Parse mode: MarkdownV2                                          ║
║  - Max message length: 4096 characters                             ║
║  - Split long content at paragraph breaks (\n\n)                   ║
║  - Escape special chars: _ * [ ] ( ) ~ ` > # + - = | { }          ║
║                                                                    ║
║  ## Structure                                                      ║
║  - Lead with key insight (first 2 lines = hook)                   ║
║  - Use bold (*text*) for key terms, sparingly                     ║
║  - Use `code` for technical terms                                  ║
║  - Bullet lists: "• " (Unicode bullet, not markdown)              ║
║  - Max 5 bullets per section                                       ║
║  - Numbered lists for sequences                                    ║
║  - Horizontal separator: "───" (Unicode, not ---)                  ║
║                                                                    ║
║  ## Tone Mapping                                                   ║
║  - analytical → structured, data-first                            ║
║  - creative → engaging, hook-driven                               ║
║  - informational → concise, scannable                             ║
║                                                                    ║
║  ## Attachments                                                    ║
║  - Tables → convert to formatted text (TG tables ugly)            ║
║  - Long reports → sendDocument (.md or .pdf)                       ║
║  - Charts → generate image → sendPhoto                            ║
║  - Multi-output → sendMediaGroup                                   ║
║                                                                    ║
║  ## Emoji Policy                                                   ║
║  - 1-2 relevant emojis per section header                         ║
║  - No emoji spam                                                   ║
║  - Use ✅ ❌ ⚠️ for status indicators                              ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ADAPTOR 2: linkedin.md                                            ║
║  ─────────────────────────                                         ║
║                                                                    ║
║  - Max: 3000 chars per post                                        ║
║  - First line = hook (shows in feed preview)                      ║
║  - White space between paragraphs (readability)                    ║
║  - 3-5 hashtags at bottom                                          ║
║  - CTA at end ("Що думаєте? Поділіться в коментарях")             ║
║  - Professional tone, insight-driven                               ║
║  - NO emoji in first line (looks spammy)                          ║
║  - Personal stories → higher engagement                           ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ADAPTOR 3: email.md (Newsletter)                                  ║
║  ────────────────────────────────                                  ║
║                                                                    ║
║  - Subject line: <60 chars, specific, no clickbait                ║
║  - Preview text: <90 chars                                         ║
║  - Structure: greeting → 1 insight → proof → CTA                  ║
║  - HTML allowed: <b>, <i>, <a href>, <br>                         ║
║  - Unsubscribe link required (legal)                               ║
║  - Personal from-name (not brand)                                  ║
║  - Mobile-first: short paragraphs, no wide tables                 ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ADAPTOR 4: instagram.md                                           ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  - Caption max: 2200 chars (but <300 shows fully in feed)         ║
║  - First line = hook                                               ║
║  - Line breaks via empty lines                                     ║
║  - Hashtags: 20-30 in first comment (not caption)                 ║
║  - Image required: describe ideal visual for generation            ║
║  - Carousel: up to 10 slides, key point per slide                 ║
║  - Reels script: 15-60 sec, hook in first 3 sec                  ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ADAPTOR 5: file_output.md                                         ║
║  ─────────────────────────────                                     ║
║                                                                    ║
║  - For: reports, audits, documents saved to files/                ║
║  - Format: proper markdown (.md) with frontmatter                  ║
║  - Frontmatter: title, date, company, author, version              ║
║  - Structure: executive summary → body → conclusions → appendix   ║
║  - Tables: standard markdown tables                                ║
║  - Code blocks: with language tags                                 ║
║  - Images: describe for future generation                          ║
║  - PDF export hints: page breaks, headers/footers                 ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ADAPTOR 6: youtube.md                                             ║
║  ────────────────────────                                          ║
║                                                                    ║
║  - Title: <70 chars, keyword-front-loaded                         ║
║  - Description: first 2 lines = summary (shows above "Show more")║
║  - Timestamps: required for videos >10min                         ║
║  - Tags: 5-10 relevant tags                                        ║
║  - Script structure: hook (0-15s) → value → CTA                   ║
║  - Thumbnail text: ≤5 words                                        ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝

ADAPTOR EXTENSIBILITY:
  Нові канали = новий .md файл у channel_adaptors/.
  Skills НЕ ЗМІНЮЮТЬСЯ при додаванні каналу.
  Agent-runner автоматично завантажує потрібний adaptor
  на основі target channel у routing metadata.
```

---

### 4.13 CROSS-FLOW INTERACTIONS MAP

```
Як 10 потоків взаємодіють:

╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  FLOW DEPENDENCY MATRIX:                                           ║
║  ────────────────────────                                          ║
║                                                                    ║
║         triggers    contains    always follows                     ║
║  A ─────────────→ E (HITL)     G (memory), J (cost)               ║
║  A ─────────────→ C (handoff)  when multi-skill needed             ║
║  B ─────────────→ G (memory)   J (cost)                            ║
║  C ─────────────→ E (HITL)     when requires_hitl=true             ║
║  D ─────────────→ C × N        sequential handoffs                 ║
║  D ─────────────→ E × M        HITL gates in pipeline              ║
║  D ─────────────→ G, J         post-pipeline                       ║
║  F ─────────────→ A (subset)   scheduled = auto-triggered A        ║
║  F ─────────────→ G, J         post-task                           ║
║  H ─────────────→ E (HITL)     confirmation before context change  ║
║  I ─────────────→ J             cost tracking for batch             ║
║                                                                    ║
║  FLOW COMPOSITION PATTERNS:                                        ║
║                                                                    ║
║  Simple request:    A → G → J                                      ║
║  With approval:     A → E → G → J                                  ║
║  Content pipeline:  A → D[C→C→E→C→C→C] → G → J                   ║
║  Scheduled report:  F → A → G → J                                  ║
║  Session transfer:  A → B → ... → B → A → G → J                   ║
║  Mass generation:   A → I → J → F[×30] → G                        ║
║  Context update:    A → H → E → G → J                              ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

### 4.14 UPDATES TO PREVIOUS PHASES

```
╔══════════════════════════════════════════════════════════════════╗
║  PHASE 4 DELTAS TO PHASE 1:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Flow list expanded from 6 (A-F) to 10 (A-J)                    ║
║    + Flow F: Scheduled Tasks (was implicit, now explicit)          ║
║    + Flow G: Memory Lifecycle (was missing — critical gap)         ║
║    + Flow H: Context Evolution (was missing)                       ║
║    + Flow I: Batch Processing (added in Phase 3)                   ║
║    + Flow J: Cost Tracking (added in Phase 3)                      ║
║                                                                    ║
║  + Memory architecture: 3-level system fully specified              ║
║    CLAUDE.md (identity+recent) + facts.jsonl + decisions.jsonl     ║
║                                                                    ║
║  + channel_adaptors/ expanded from 3 to 6 specs                    ║
║    + instagram.md, youtube.md, file_output.md                      ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 4 DELTAS TO PHASE 2:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + sendMessageDraft streaming protocol detailed                    ║
║  + MarkdownV2 escaping rules specified                             ║
║  + Text splitting algorithm for >4096 char messages                ║
║  + Error handling cascade (429, 400, 403, 5xx)                     ║
║  + HITL → InlineKeyboard mapping fully specified                   ║
║  + CallbackQuery handling protocol                                 ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 4 DELTAS TO PHASE 3:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + 3-layer system prompt assembly detailed (what goes where)       ║
║  + Model selection per pipeline step specified                     ║
║  + Session Transfer Protocol: 3 types fully specified              ║
║  + Batch API workflow: preparation → submission → monitoring       ║
║  + Cost tracking: schema, budgets, alerts, model downgrade cascade ║
║  + Memory retrieval: topic-based grep for facts.jsonl              ║
║  + Prompt cache invalidation on context change                     ║
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

*Фаза 4 завершена. Готовий до Фази 5.*
Compacting our conversation so we can keep chatting...
69%
