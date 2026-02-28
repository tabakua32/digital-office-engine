# NanoClaw OS — Генеральний Архітектурний План v5.0

**Version**: 5.0 FINAL
**Date**: 2026-02-28
**Status**: Кінцевий дизайн
**Scope**: Фаза 1 з 5 — ГЕНЕРАЛЬНА ТОПОЛОГІЯ

---

## ФАЗА 1: ГЕНЕРАЛЬНА ТОПОЛОГІЯ СИСТЕМИ

---

### 1.1 ОДНЕ РЕЧЕННЯ

NanoClaw OS — операційна система для AI-маркетинг-відділу,
де **один NanoClaw-інстанс на одного власника** оркеструє
маркетингові агенти для **N компаній/субпроектів** через
**Telegram як первинний інтерфейс** та **Claude як інтелект**,
з можливістю переносу сесій у Claude.ai, Claude Code та Cowork
для задач що потребують іншого UX.

---

### 1.2 ДВІ ПЛАТФОРМИ, РІЗНІ РОЛІ

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                     NanoClaw OS                                       │
│                                                                       │
│   ┌─────────────────────────┐     ┌──────────────────────────────┐  │
│   │      TELEGRAM            │     │         CLAUDE               │  │
│   │      = ІНТЕРФЕЙС         │     │         = ІНТЕЛЕКТ           │  │
│   │                          │     │                              │  │
│   │  Що бачить і робить      │     │  Що думає і вирішує          │  │
│   │  ВЛАСНИК та його КЛІЄНТИ │     │                              │  │
│   │                          │     │  Claude Agent SDK (ядро)     │  │
│   │  Повідомлення, медіа,    │     │  Opus / Sonnet / Haiku      │  │
│   │  inline keyboards,       │     │  Extended Thinking           │  │
│   │  Mini Apps, голос,       │     │  MCP інструменти             │  │
│   │  платежі, канали,        │     │  Web Search / Fetch          │  │
│   │  форуми, топіки          │     │  Code Execution              │  │
│   └────────────┬─────────────┘     └──────────────┬───────────────┘  │
│                │                                  │                   │
│                └──────────────┬───────────────────┘                   │
│                               │                                       │
│                        NanoClaw Node.js                               │
│                        ~2,500 LOC                                     │
│                        SQLite + IPC + Containers                      │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘

ДОПОМІЖНІ RUNTIME'и (не замість, а НА ДОДАТОК):
┌──────────────┬───────────────────────────────────────────────────┐
│ Claude.ai    │ Глибокий аналіз, 200K контекст, артефакти,       │
│              │ Extended Thinking з прозорістю, File Creation.    │
│              │ Коли задача потребує ДІАЛОГУ зі стратегічною      │
│              │ глибиною яку месенджер не дає.                    │
├──────────────┼───────────────────────────────────────────────────┤
│ Claude Code  │ Термінал розробника: створення/тестування скілів, │
│              │ MCP інтеграції, batch processing, debug.          │
│              │ Коли власник БУДУЄ або ЧИНИТЬ систему.             │
├──────────────┼───────────────────────────────────────────────────┤
│ Cowork       │ GUI для нетехнічних задач: web research → файли.  │
│              │ Коли потрібно делегувати і забути.                │
└──────────────┴───────────────────────────────────────────────────┘
```

**Принципове рішення**: NanoClaw + Telegram = PRIMARY runtime.
Інші runtime'и = ESCAPE HATCHES для задач де месенджер обмежує.
Архітектура гарантує що БУДЬ-ЯКА робота почата в одному runtime
може бути ПРОДОВЖЕНА в іншому без втрати контексту.

---

### 1.3 OWNERSHIP MODEL: 1 ІНСТАНС = 1 ВЛАСНИК = N КОМПАНІЙ

```
                         ┌─────────────────────┐
                         │      ВЛАСНИК          │
                         │  (1 NanoClaw інстанс) │
                         └──────────┬────────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                    │
          ┌──────▼──────┐   ┌──────▼──────┐     ┌──────▼──────┐
          │  Компанія A  │   │ Субпроект B │     │  Клієнт C   │
          │  (ЯКоманда)  │   │  (Курс)     │     │  (Фрілан)   │
          │              │   │              │     │              │
          │ TG group:    │   │ TG group:    │     │ TG group:    │
          │  yakomanda   │   │  course      │     │  client-c    │
          │              │   │              │     │              │
          │ Context:     │   │ Context:     │     │ Context:     │
          │  ПОВНИЙ      │   │ СПІЛЬНЕ ↗    │     │  ІЗОЛЬОВАНИЙ │
          │  (5 модулів) │   │ + ВЛАСНЕ     │     │  (5 модулів) │
          └──────────────┘   └──────────────┘     └──────────────┘

ТРИ ТИПИ ЗВ'ЯЗКУ МІЖ КОМПАНІЯМИ:

① ПОВНІСТЮ ІЗОЛЬОВАНІ (client-c)
   Окремий контекст, окрема пам'ять, окремий контейнер.
   Агент в контейнері client-c НЕ ЗНАЄ про існування yakomanda.
   Ізоляція на рівні OS (container/hypervisor), не application.

② СУБПРОЕКТ ІЗ СПІЛЬНИМ ЯДРОМ (course)
   Наслідує company/identity + brand/ від батьківської компанії.
   Має ВЛАСНІ product/, audience/, market/.
   Реалізація: symlinks або copy-on-read.

③ АДМІН (main group)
   Бачить ВСІ компанії. Єдиний хто може:
   ├── register_group (додати нову компанію)
   ├── list_available_groups (побачити всі)
   ├── schedule cross-company tasks
   └── export/transfer sessions

МАКСИМАЛЬНА МОДЕЛЬ (для курсмейкера з клієнтами):
┌────────────────────────────────────────────────────┐
│  main (admin, self-chat)                             │
│    ├── yakomanda/        ← власна компанія           │
│    │     └── course/     ← субпроект (курс)          │
│    ├── client-a/         ← клієнт фрілансу           │
│    ├── client-b/         ← клієнт фрілансу           │
│    └── pilot-students/   ← група студентів пілоту    │
└────────────────────────────────────────────────────┘
```

---

### 1.4 ЧОТИРИ ШАРИ АРХІТЕКТУРИ

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  LAYER 3: DOMAIN SKILLS (каноничні, platform-agnostic)               ║
║                                                                      ║
║  marketing/ │ dev-ops/ │ visual/ │ data/ │ communication/ │ meta/    ║
║      ×                                                               ║
║  agent │ skill │ connector │ command │ module │ process               ║
║                                                                      ║
║  Один SKILL.md → працює на БУДЬ-ЯКОМУ runtime                        ║
║  Не знає про Telegram. Не знає про NanoClaw.                         ║
║  Знає тільки про КОНТЕКСТ (Layer 2) і СТАНДАРТ (Layer 1).           ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  LAYER 2: CONTEXT MODULES (per-company, людина контролює)            ║
║                                                                      ║
║  company/ │ product/ │ audience/ │ brand/ │ market/                   ║
║  17 файлів, structured markdown зі schema                            ║
║                                                                      ║
║  Заповнюються при onboarding. Оновлюються періодично.                ║
║  Зберігаються в Canonical Store (Git).                               ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  LAYER 1: FOUNDATION (будується один раз)                            ║
║                                                                      ║
║  Skill Standard │ Taxonomy │ Evaluation │ Handoff Protocol           ║
║  Output Templates │ Channel Adaptors │ Process Templates             ║
║  Skill Factory │ Context Extraction │ Connector Standard             ║
║  Memory Architecture (CLAUDE.md + JSONL + future: vectors)           ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  RUNTIME LAYER (platform-specific, тонкий адаптер)                   ║
║                                                                      ║
║  ┌────────────────────────────────────────────────────────────┐      ║
║  │  NanoClaw Runtime (PRIMARY)                                 │      ║
║  │  ├── telegram.ts / whatsapp.ts   (channel adapters)        │      ║
║  │  ├── container-runner.ts          (OS-level isolation)      │      ║
║  │  ├── group-queue.ts               (concurrency control)    │      ║
║  │  ├── task-scheduler.ts            (cron/interval/once)     │      ║
║  │  ├── ipc.ts                       (container ↔ host)       │      ║
║  │  └── db.ts                        (SQLite state)           │      ║
║  └────────────────────────────────────────────────────────────┘      ║
║                                                                      ║
║  ┌──────────────┐ ┌───────────┐ ┌──────────┐                        ║
║  │  Claude.ai   │ │Claude Code│ │  Cowork  │  (auxiliary)            ║
║  └──────────────┘ └───────────┘ └──────────┘                        ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

КЛЮЧОВИЙ ПРИНЦИП: Layers 1-3 = PLATFORM-AGNOSTIC.
Runtime = тонкий адаптер.
Якщо Telegram зникне → заміна ТІЛЬКИ telegram.ts + channel_adaptors/.
Якщо Claude зникне → заміна ТІЛЬКИ container-runner + agent-runner.
Layers 1-3 = інвестиція що не знецінюється.
```

---

### 1.5 CANONICAL STORE: ЄДИНЕ ДЖЕРЕЛО ПРАВДИ

```
yakomanda-os/                              ← Git repo (private)
│
├── foundation/                            ← LAYER 1
│   ├── skill_standard.md
│   ├── skill_taxonomy.md
│   ├── evaluation_framework.md
│   ├── handoff_protocol.md
│   ├── connector_standard.md
│   ├── output_templates/
│   │   ├── analytical.md
│   │   ├── generative.md
│   │   ├── transformational.md
│   │   └── orchestration.md
│   ├── channel_adaptors/
│   │   ├── telegram.md                    4096 char, MarkdownV2, keyboards
│   │   ├── whatsapp.md                    65536 char, limited formatting
│   │   ├── web_artifact.md                React/HTML для Claude.ai
│   │   └── file_output.md                 docx/xlsx/pptx
│   └── process_templates/
│       ├── campaign_launch.md
│       ├── content_pipeline.md
│       ├── client_onboarding.md
│       ├── competitive_intel.md
│       └── skill_creation.md
│
├── skills/                                ← LAYER 3
│   ├── marketing/                         14 sub-domains (Chain ①-⑫)
│   │   ├── market-intelligence/
│   │   │   ├── analyst/
│   │   │   │   ├── SKILL.md               < 500 рядків
│   │   │   │   └── references/            деталі, фреймворки
│   │   │   └── competitor-monitor/
│   │   ├── customer-analysis/
│   │   ├── pmf/
│   │   ├── positioning/
│   │   ├── offer/
│   │   ├── brand/
│   │   ├── content/
│   │   │   ├── strategist/                (agent)
│   │   │   ├── copywriter/                (skill)
│   │   │   ├── seo-analyst/               (skill)
│   │   │   ├── editor/                    (skill)
│   │   │   └── repurposer/               (skill)
│   │   ├── geo-aeo/
│   │   ├── distribution/
│   │   ├── conversion/
│   │   ├── cx/
│   │   ├── retention/
│   │   ├── analytics/
│   │   ├── scaling/
│   │   └── feedback/
│   │
│   ├── dev-ops/
│   │   ├── debugging/
│   │   ├── testing/
│   │   ├── security/
│   │   │   ├── prompt-injection-guard/
│   │   │   └── credentials-encryption/
│   │   ├── deployment/
│   │   ├── monitoring/
│   │   │   ├── cost-tracker/
│   │   │   ├── rate-limit-handler/
│   │   │   └── bot-health-monitor/
│   │   └── bot-ops/
│   │
│   ├── visual/
│   │   ├── graphic-design/
│   │   ├── ui-ux/
│   │   ├── video/
│   │   ├── infographic/
│   │   └── brand-identity/
│   │
│   ├── data/
│   │   ├── analytics/
│   │   ├── reporting/
│   │   ├── etl/
│   │   └── visualization/
│   │
│   ├── communication/
│   │   ├── email/
│   │   ├── social-media/
│   │   │   ├── telegram/                  TG як МАРКЕТИНГОВИЙ канал
│   │   │   │   ├── channel-manager/       публікація, розклад
│   │   │   │   ├── group-moderator/       модерація, FAQ
│   │   │   │   └── forum-manager/         теми, структура
│   │   │   ├── linkedin/
│   │   │   ├── instagram/
│   │   │   └── youtube/
│   │   ├── messenger/                     1:1 взаємодія
│   │   ├── voice/                         Голосовий I/O
│   │   │   ├── transcription/             Whisper / Groq
│   │   │   └── tts/                       Piper / ElevenLabs
│   │   ├── pr/
│   │   └── community/
│   │
│   └── meta/
│       ├── factory/
│       ├── audit/
│       ├── orchestration/
│       ├── routing/
│       └── extraction/
│
├── connectors/                            ← MCP конфігурації
│   ├── telegram-mcp/                      TG як зовнішній інструмент
│   │   ├── SKILL.md
│   │   ├── .mcp.json
│   │   └── references/
│   │       └── api-mapping.md
│   ├── notion-mcp/
│   ├── google-ads-mcp/
│   ├── canva-mcp/
│   ├── google-analytics-mcp/
│   ├── perplexity-mcp/
│   └── .../
│
├── companies/                             ← LAYER 2 (per-company)
│   ├── yakomanda/
│   │   ├── context/
│   │   │   ├── company/
│   │   │   │   ├── identity.md
│   │   │   │   ├── team.md
│   │   │   │   └── operations.md
│   │   │   ├── product/
│   │   │   │   ├── spec.md
│   │   │   │   ├── pricing.md
│   │   │   │   └── positioning.md
│   │   │   ├── audience/
│   │   │   │   ├── icp.md
│   │   │   │   ├── jtbd.md
│   │   │   │   ├── voc.md
│   │   │   │   └── awareness.md
│   │   │   ├── brand/
│   │   │   │   ├── voice.md
│   │   │   │   ├── visual.md
│   │   │   │   └── guidelines.md
│   │   │   └── market/
│   │   │       ├── intelligence.md
│   │   │       ├── competitors.md
│   │   │       ├── channels.md
│   │   │       └── geo_aeo.md
│   │   └── memory/                        ← RUNTIME (агент оновлює)
│   │       ├── CLAUDE.md                  identity + recent state
│   │       ├── facts.jsonl                extracted facts (append-only)
│   │       └── decisions.jsonl            key decisions (append-only)
│   │
│   ├── yakomanda-course/                  ← Субпроект
│   │   ├── context/
│   │   │   ├── company/ → ../yakomanda/context/company  (НАСЛІДУЄ)
│   │   │   ├── brand/   → ../yakomanda/context/brand    (НАСЛІДУЄ)
│   │   │   ├── product/                   ← ВЛАСНИЙ
│   │   │   ├── audience/                  ← ВЛАСНИЙ
│   │   │   └── market/                    ← ВЛАСНИЙ
│   │   └── memory/
│   │
│   └── client-x/                          ← Повна ізоляція
│       ├── context/
│       └── memory/
│
└── runtime/                               ← Platform-specific
    ├── nanoclaw/
    │   ├── sync.sh                        git pull → mount refresh
    │   └── mapping.yaml                   canonical → NanoClaw paths
    ├── claude-code/
    │   └── mapping.yaml                   canonical → .claude/ paths
    └── claude-ai/
        └── mapping.yaml                   canonical → Project KB
```

---

### 1.6 ІНФОРМАЦІЙНА ТОПОЛОГІЯ (Bird's Eye)

```
═══════════════════════════════════════════════════════════════
ПОТІК A: ВХІДНИЙ (людина → система)
═══════════════════════════════════════════════════════════════

 Власник/Клієнт                    NanoClaw
 ┌────────────┐                    ┌─────────────────────┐
 │            │ ── текст ────────→ │                     │
 │  Telegram  │ ── голос ────────→ │ channel adapter     │
 │  (або WA)  │ ── фото/відео ──→ │ (telegram.ts)       │
 │            │ ── документ ─────→ │                     │
 │            │ ── callback ─────→ │ (inline keyboards)  │
 │            │ ── location ─────→ │                     │
 │            │ ── payment ──────→ │ (Telegram Payments)  │
 └────────────┘                    └──────────┬──────────┘
                                              │
                                              ▼
                                    SQLite → Message Loop → Container
                                    (polling 2s)    (OS isolated)
                                                         │
                                                    Claude Agent SDK
                                                    (inside container)

═══════════════════════════════════════════════════════════════
ПОТІК B: ВИХІДНИЙ (система → людина)
═══════════════════════════════════════════════════════════════

 Agent Runner (container)
    │
    ├── streaming stdout → router → telegram.ts → Telegram
    │                                    │
    │                             channel adaptor:
    │                             ├── chunk ≤ 4096 chars
    │                             ├── markdown → MarkdownV2
    │                             ├── + inline keyboard (HITL)
    │                             └── + media attachment
    │
    └── IPC files → ipc.ts → router → (інший чат або task)

═══════════════════════════════════════════════════════════════
ПОТІК C: АГЕНТ → АГЕНТ (Handoff)
═══════════════════════════════════════════════════════════════

 Intra-session:  Orchestrator → sub-agent → result (один контейнер)
 Inter-session:  Agent A → handoff.json → Agent B (різні контейнери)
 Cross-platform: Agent A → git push → Agent B в іншому runtime

 Handoff = structured JSON:
 {from, to, payload{content, confidence, evidence_grade, gaps},
  constraints{tone_isolation, max_tokens, requires_hitl},
  metadata{created_at, ttl_hours, chain_id, step}}

═══════════════════════════════════════════════════════════════
ПОТІК D: SCHEDULED (система → система → людина)
═══════════════════════════════════════════════════════════════

 Scheduler (кожні 60s) → check SQLite → spawn container → result → TG
 Три типи: cron | interval | once
 Створюються юзером ("кожен понеділок о 9") або агентом (IPC task)

═══════════════════════════════════════════════════════════════
ПОТІК E: SESSION TRANSFER (між runtime'ами)
═══════════════════════════════════════════════════════════════

 NanoClaw                    Git / file              Claude.ai
 /export-session ──────→ session_transfer.md ──────→ "Продовж з кроку 4"
 (CLAUDE.md + messages    (self-contained             (upload або
  + handoffs + context     snapshot, достатній         MCP Google Drive)
  + recent memory)         для будь-якого runtime)

═══════════════════════════════════════════════════════════════
ПОТІК F: CONTEXT UPDATE (рідкісний, людина ініціює)
═══════════════════════════════════════════════════════════════

 ① Extraction agents (semi-auto): /extract-context → інтерв'ю + скрапінг
 ② Manual edit: правка context/*.md у Git repo
 ③ Implicit accumulation: memory/ оновлюється КОЖНУ сесію (авто)
    → Extraction agents можуть ПРОПОНУВАТИ оновлення context на основі memory
```

---

### 1.7 ШІСТЬ ДОМЕНІВ × ШІСТЬ ФУНКЦІЙ (Red Team corrected)

```
ДОМЕНИ (MECE по предметній області):

DOMAIN           │ SCOPE                              │ CHAIN
─────────────────┼────────────────────────────────────┼───────────
marketing/       │ Повний Marketing Chain v3          │ ①-⑫
dev-ops/         │ Інфраструктура: debug, test,       │ cross
                 │ security, deploy, monitor, bot-ops │
visual/          │ Дизайн, відео, інфографіка         │ ④.5 ⑤ ⑥
data/            │ Аналітика, звітність, ETL          │ ⑩ ⑫
communication/   │ Канали: email, social, messenger,  │ ⑥ ⑦ ⑧
                 │ voice, PR, community               │
meta/            │ Factory, audit, orchestration,     │ cross
                 │ routing, extraction                │

⚠️ RED TEAM: НЕМАЄ домену platform/.
  TG як UI → runtime layer. TG як канал → communication/.
  Bot ops → dev-ops/. Voice → communication/voice/.

ФУНКЦІЇ (MECE по типу дії):

FUNCTION   │ АВТОН.  │ ЩО РОБИТЬ                    │ MODEL TIER
───────────┼─────────┼──────────────────────────────┼────────────
agent      │ HIGH    │ Планує, делегує, вирішує      │ Opus / Sonnet
skill      │ MEDIUM  │ Виконує задачу за запитом     │ Sonnet / Haiku
connector  │ LOW     │ MCP bridge до зовнішнього API │ N/A (config)
command    │ LOW     │ Slash-команда, атомарна       │ Haiku
module     │ NONE    │ Контекстний блок (data only)  │ N/A (file)
process    │ ORCH.   │ Multi-step workflow           │ Opus + mixed
```

---

### 1.8 DESIGN PRINCIPLES (14 принципів, v5 final)

```
 1. MECE EVERYWHERE
    Жодних перетинів між доменами, функціями, модулями.

 2. PLATFORM-AGNOSTIC SKILLS
    SKILL.md не знає про Telegram. Channel Adaptor — останній крок.

 3. TELEGRAM-FIRST UX
    Telegram = primary interface. Повний API (Фаза 2).
    Але skills не прив'язані до TG.

 4. 1 NANOCLAW = 1 OWNER
    Не multi-tenant SaaS. N компаній через OS-ізольовані groups.

 5. STANDARD-FIRST
    Спочатку стандарт (Layer 1), потім контент (Layer 3).

 6. EVIDENCE-GRADED
    Evidence grades з Marketing Chain v3.

 7. CONTEXT-FED
    Агенти читають Context Modules перед виконанням.

 8. HANDOFF-NATIVE
    Формальні JSON контракти між агентами.

 9. MEMORY ≠ CONTEXT
    Context = статичне, людина. Memory = динамічне, агент.

10. APPEND-ONLY MEMORY
    facts/decisions.jsonl = append-only, no merge conflicts.

11. PROGRESSIVE DISCLOSURE
    SKILL.md < 500 рядків. Деталі → references/.

12. WRITE FROM SCRATCH, RESEARCH FOR PATTERNS
    200+ repos = патерни. Код = свій.

13. BOOTSTRAP SPIRAL
    Мінімальне ядро → розширення → валідація → ітерація.

14. FUTURE-PROOF INTERFACES
    TG evolves → channel adaptor update, skills untouched.
    Claude evolves → container-runner update, skills untouched.
```

---

### 1.9 BUILD PHASES

```
PHASE 0 — FOUNDATION (2-3 сесії)
├── 00A: Skill Standard + Taxonomy Matrix
└── 00B: Evaluation + Handoff + Output Templates +
         Channel Adaptors + Process Templates

PHASE 1 — ANALYSIS (4-6 сесій)
├── 01:  Anthropic official: cookbook, SDK, plugins
├── 02:  Claude system prompts (DONE)
├── 02B: Non-Claude prompts
├── 07A: Auto-inventory 200 repos
├── 07B: Deep analysis
└── 07C: Synthesis

PHASE 2 — CONTEXT (1-2 сесії)
├── 08A: Context Module Architecture
└── 08B: Extraction Process

PHASE 3 — FACTORY (2-3 сесії)
├── 05:  Build Skill Factory
└── 06:  Validate on 5 test skills

PHASE 4 — DEV TEAM (1-2 сесії)
├── 09A: Generate dev-ops skills
└── 09B: Validate factory

PHASE 5 — DOMAIN SKILLS (5-10 сесій)
└── 10:  Batch generation

PHASE 6 — INTEGRATION (2-3 сесії)
└── 11:  End-to-end testing
```

---

## НАСТУПНІ ФАЗИ ДОКУМЕНТУ

```
ФАЗА 2: TELEGRAM PLATFORM LAYER
  Bot API повна карта. MTProto. Mini Apps. Payments/Stars.
  Channels/Groups/Forums. Media. Inline Mode. Business API.
  Як NanoClaw використовує КОЖНУ можливість.

ФАЗА 3: CLAUDE PLATFORM LAYER & RUNTIMES
  Claude API повна карта. Модельний матрикс.
  Extended Thinking. MCP. Batch + Caching.
  Session management per runtime.

ФАЗА 4: INFORMATION FLOWS & MEMORY (деталі)
  Детальні діаграми кожного потоку. 3-рівнева memory.
  Cross-platform continuity. HITL convention.
  Channel adaptors specs.

ФАЗА 5: DEPLOYMENT, SECURITY & EVOLUTION
  Масштабування. Security. Future-proofing.
  Quarterly roadmap Q1-Q4 2026.
```

---

*Фаза 1 завершена. Готовий до Фази 2.*