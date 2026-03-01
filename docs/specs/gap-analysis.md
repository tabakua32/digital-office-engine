# NanoClaw OS — Gap Analysis (STEP 2)

> Аналіз + маппінг: архітектура → патерни → вердикти → ТЗ групи
> Дата: 2026-03-01 | Статус: COMPLETE

---

## Зведена статистика

| Phase | COPY | ADAPT | BUILD | DEFER | Total | TZ Groups |
|-------|------|-------|-------|-------|-------|-----------|
| **Phase 0** (Foundation) | 11 (15%) | 23 (31%) | 27 (36%) | 14 (19%) | 75 | TZ-0.1 — TZ-0.7 |
| **Phase 1** (Topology) | 11 (16%) | 27 (40%) | 13 (19%) | 16 (24%) | 67 | TZ-1.1 — TZ-1.5 |
| **Phase 2** (Telegram Bot) | 18 (25%) | 24 (33%) | 15 (21%) | 16 (22%) | 73 | TZ-2.1 — TZ-2.8 |
| **Phase 2.5** (MTProto) | 9 (11%) | 27 (33%) | 28 (35%) | 8 (10%) | 72 | TZ-2.5.1 — TZ-2.5.12 |
| **Phase 3** (Claude Platform) | 4 (13%) | 13 (43%) | 11 (37%) | 2 (7%) | 30 | TZ-3.1 — TZ-3.6 |
| **Phase 4** (Info Flows) | 0 (0%) | 20 (39%) | 22 (43%) | 9 (18%) | 51 | TZ-4.1 — TZ-4.8 |
| **Phase 5** (Deployment) | 11 (26%) | 16 (37%) | 10 (23%) | 6 (14%) | 43 | TZ-5.1 — TZ-5.4 |
| **TOTAL** | **64 (15%)** | **150 (36%)** | **126 (30%)** | **71 (17%)** | **411** | **50 TZ** |

### Ключові висновки

1. **Phase 4 найважча** — 43% BUILD, 0% COPY. 10 інформаційних потоків + 3-рівнева пам'ять = майже повністю кастомна робота
2. **Phase 5 найлегша** — 26% COPY (стандартні Docker/Linux/git патерни)
3. **Phase 0 = фундамент** — 36% BUILD через відсутність стандартів скілів у відкритих репо
4. **Phase 2 найкраще покрита** — 58% COPY+ADAPT завдяки claudegram, telegram-mcp, RichardAtCT
5. **Phase 2.5 ризикована** — 35% BUILD + anti-ban engine = найвищий технічний ризик

---

## TZ MASTER LIST

### Критичний шлях (must-have для MVP)

| TZ | Phase | Назва | Sessions | Priority | Залежності |
|----|-------|-------|----------|----------|------------|
| **TZ-0.1** | 0 | Skill Standard + Taxonomy | 2-3 | P0 | — (root) |
| **TZ-0.2** | 0 | Evaluation System (Rubric) | 1-2 | P0 | TZ-0.1 |
| **TZ-0.3** | 0 | Template Factory | 2-3 | P0 | TZ-0.1 |
| **TZ-1.1** | 1 | Ownership Model + Group Registration | 2-3 | P0 | TZ-0.1 |
| **TZ-1.2** | 1 | 4-Layer Architecture + Canonical Store | 2-3 | P0 | TZ-1.1 |
| **TZ-1.3** | 1 | Core Information Flows (discovery, inbound, outbound) | 2-3 | P0 | TZ-1.2 |
| **TZ-2.1** | 2 | Core Bot Runtime | 2-3 | P0 | TZ-1.2 |
| **TZ-2.2** | 2 | Channel Adaptor Engine | 2-3 | P0 | TZ-2.1 |
| **TZ-2.3** | 2 | HITL & Streaming | 2-3 | P0 | TZ-2.1 |
| **TZ-3.1** | 3 | Claude API Core Integration | 2-3 | P0 | TZ-1.2 |
| **TZ-3.2** | 3 | Model Selection + Cost Framework | 2-3 | P1 | TZ-3.1 |
| **TZ-4.1** | 4 | Core Flows Engine (A-D) | 2-3 | P0 | TZ-1.3, TZ-2.2, TZ-3.1 |
| **TZ-5.1** | 5 | Docker Deployment Base | 2-3 | P0 | TZ-1.2 |

### Високий пріоритет (P1 — потрібно для повноцінного MVP)

| TZ | Phase | Назва | Sessions | Priority | Залежності |
|----|-------|-------|----------|----------|------------|
| **TZ-0.4** | 0 | Handoff Protocol | 1-2 | P1 | TZ-0.1 |
| **TZ-0.5** | 0 | Output Format Standard | 1-2 | P1 | TZ-0.1 |
| **TZ-1.4** | 1 | Forum Thread Hierarchy + Context Modules | 2-3 | P1 | TZ-1.2 |
| **TZ-2.4** | 2 | Voice I/O Pipeline | 1-2 | P1 | TZ-2.1 |
| **TZ-2.5** | 2 | Forums & Group Management | 2-3 | P1 | TZ-2.1 |
| **TZ-2.6** | 2 | Moderation & Security | 1-2 | P1 | TZ-2.1, TZ-2.5 |
| **TZ-2.7** | 2 | Channel Publishing | 2-3 | P1 | TZ-2.1, TZ-2.2 |
| **TZ-2.5.1** | 2.5 | GramJS Core Client | 2-3 | P1 | TZ-2.1 |
| **TZ-2.5.2** | 2.5 | Anti-Ban Engine | 2-3 | P1 | TZ-2.5.1 |
| **TZ-2.5.3** | 2.5 | Channel Coordinator (Bot↔User routing) | 2-3 | P1 | TZ-2.5.1, TZ-2.5.2 |
| **TZ-2.5.4** | 2.5 | IPC Extension (15 tg_* tools) | 2-3 | P1 | TZ-2.5.3 |
| **TZ-2.5.5** | 2.5 | History & Search | 2-3 | P1 | TZ-2.5.4 |
| **TZ-3.3** | 3 | Caching & Context Budget | 2-3 | P1 | TZ-3.1 |
| **TZ-4.2** | 4 | Extended Flows (E-G: HITL, background, notification) | 2-3 | P1 | TZ-4.1 |
| **TZ-4.3** | 4 | 3-Level Memory System | 2-3 | P1 | TZ-4.1, TZ-3.1 |
| **TZ-5.2** | 5 | Security Hardening (22 items) | 2-3 | P1 | TZ-5.1 |

### Середній пріоритет (P2 — розширення після MVP)

| TZ | Phase | Назва | Sessions | Priority | Залежності |
|----|-------|-------|----------|----------|------------|
| **TZ-0.6** | 0 | Process Templates | 1-2 | P2 | TZ-0.1 |
| **TZ-0.7** | 0 | Integration Tests + Quality Gate | 1-2 | P2 | TZ-0.2, TZ-0.3 |
| **TZ-1.5** | 1 | Extended Flows (HITL, background) + Session Transfer | 2-3 | P2 | TZ-1.3 |
| **TZ-2.8** | 2 | Advanced: Payments, Stories, Business | 2-3 | P2 | TZ-2.7 |
| **TZ-2.5.6** | 2.5 | Members & Contacts | 1-2 | P2 | TZ-2.5.4 |
| **TZ-2.5.7** | 2.5 | Group/Channel Management | 2-3 | P2 | TZ-2.5.4 |
| **TZ-2.5.8** | 2.5 | Analytics & Intelligence | 2-3 | P2 | TZ-2.5.5, TZ-2.5.6 |
| **TZ-2.5.9** | 2.5 | Content Publishing (as User) | 2-3 | P2 | TZ-2.5.3, TZ-2.5.7 |
| **TZ-2.5.10** | 2.5 | Large File Operations (4GB) | 1-2 | P2 | TZ-2.5.1 |
| **TZ-2.5.11** | 2.5 | Profile & Account Management | 1-2 | P2 | TZ-2.5.1 |
| **TZ-2.5.12** | 2.5 | Discovery Pipeline v2 | 1-2 | P2 | TZ-2.5.5, TZ-2.5.8 |
| **TZ-3.4** | 3 | Batch API + Background Processing | 1-2 | P2 | TZ-3.1 |
| **TZ-3.5** | 3 | MCP Server Integration | 2-3 | P2 | TZ-3.1 |
| **TZ-3.6** | 3 | Multi-Agent Orchestration | 2-3 | P2 | TZ-3.2, TZ-4.3 |
| **TZ-4.4** | 4 | Specialty Flows (H-J: escalation, analytics, audit) | 2-3 | P2 | TZ-4.2 |
| **TZ-4.5** | 4 | Knowledge Graph Layer | 2-3 | P2 | TZ-4.3 |
| **TZ-4.6** | 4 | HITL Convention System | 2-3 | P2 | TZ-4.2 |
| **TZ-4.7** | 4 | Cross-Session State | 1-2 | P2 | TZ-4.3 |
| **TZ-4.8** | 4 | Automated Workflows (scheduled, cyclic) | 2-3 | P2 | TZ-4.1, TZ-4.2 |
| **TZ-5.3** | 5 | Monitoring & Observability | 2-3 | P2 | TZ-5.1 |
| **TZ-5.4** | 5 | Scaling (S0→S1→S2) | 2-3 | P2 | TZ-5.1, TZ-5.2 |

---

## Оцінка зусиль

| Priority | TZ Count | Sessions | Тижні (1 session/day) |
|----------|----------|----------|-----------------------|
| P0 (Critical) | 13 | 26-39 | 5-8 тижнів |
| P1 (High) | 16 | 32-48 | 6-10 тижнів |
| P2 (Medium) | 21 | 38-52 | 8-11 тижнів |
| **TOTAL** | **50** | **96-139** | **19-28 тижнів** |

---

## Phase 0: Foundation — Деталі

### Вердикти по компонентах

| Область | Компоненти | COPY | ADAPT | BUILD | DEFER |
|---------|-----------|------|-------|-------|-------|
| Skill Standard | 12 | 1 | 4 | 6 | 1 |
| Taxonomy | 8 | 1 | 3 | 3 | 1 |
| Evaluation | 10 | 0 | 4 | 5 | 1 |
| Templates | 15 | 4 | 5 | 4 | 2 |
| Handoff Protocol | 10 | 1 | 2 | 4 | 3 |
| Output Format | 8 | 2 | 2 | 2 | 2 |
| Process Defs | 12 | 2 | 3 | 3 | 4 |

### TZ-0.1: Skill Standard + Taxonomy
**Sessions:** 2-3 | **Priority:** P0 (root — все залежить від цього)

**Scope:**
- Skill interface (manifest.yaml, lifecycle hooks: init/execute/cleanup)
- Naming convention (category.domain.action)
- Taxonomy hierarchy (Marketing Chain departments → categories → skills)
- Skill registry schema (SQLite canonical store)
- Versioning strategy (semver for skills)

**Verdict mix:** BUILD 60% — немає відкритого стандарту скілів з повним lifecycle
**Key references:**
- ADAPT: Anthropic knowledge-work plugins (18 шт) — структура skill manifest
- ADAPT: `My_skill_and_insite/skill_antropic Complete Guide.md` — офіційний guide
- ADAPT: `claude_skills/README.md` — плагін-фреймворк
- BUILD: Marketing Chain taxonomy (MECE Matrix v5) → NanoClaw-specific mapping

### TZ-0.2: Evaluation System
**Sessions:** 1-2 | **Priority:** P0

**Scope:**
- 100-point rubric (adapted from user's existing rubric)
- Auto-check criteria (schema validation, test coverage, docs completeness)
- Scoring engine (per-skill quality metrics)
- Evaluation report format

**Verdict mix:** ADAPT 50% — рубрика є, потрібна автоматизація
**Key references:**
- ADAPT: `My_skill_and_insite/` — existing 100-point rubric
- ADAPT: `Analysis_reports_md/` — evaluation methodology examples
- BUILD: Auto-check engine (no reference)

### TZ-0.3: Template Factory
**Sessions:** 2-3 | **Priority:** P0

**Scope:**
- Skill template (scaffold generator: files, structure, manifest)
- Agent template (system prompt, tools config, personality)
- Command template (trigger, handler, permissions)
- Context placeholder system

**Verdict mix:** ADAPT 45% — є багато прикладів плагінів
**Key references:**
- COPY: 18 Anthropic knowledge-work plugins (customer-support, engineering, data, finance...)
- ADAPT: `marketing_skills_repo/` — 24 skill collections structure
- ADAPT: NanoClaw `src/agents/` — existing agent template pattern
- BUILD: Context placeholder engine

### TZ-0.4: Handoff Protocol
**Sessions:** 1-2 | **Priority:** P1

**Scope:**
- Cascade check (skill A → skill B transition rules)
- Tone isolation (кожен скіл має свій тон)
- State transfer format (context passing between skills)
- Error escalation path

**Verdict mix:** BUILD 60% — унікальна для NanoClaw логіка
**Key references:**
- ADAPT: Claude system prompts (handoff patterns)
- BUILD: Cascade check logic (no reference)
- BUILD: Tone isolation system (no reference)

### TZ-0.5: Output Format Standard
**Sessions:** 1-2 | **Priority:** P1

**Scope:**
- Telegram-optimized markdown (MarkdownV2 constraints)
- Media attachment conventions
- Report templates (analytics, status, alerts)
- Multi-format output (text, voice, file)

**Verdict mix:** ADAPT 50%
**Key references:**
- ADAPT: claudegram (MarkdownV2 conversion patterns)
- ADAPT: `type_scripts_docs/` — TS formatting best practices
- BUILD: Report template system

### TZ-0.6: Process Templates
**Sessions:** 1-2 | **Priority:** P2

**Scope:**
- Task lifecycle (created → assigned → in_progress → review → done)
- Scheduled task templates (cron-like definitions)
- Workflow definitions (multi-step processes)

**Verdict mix:** ADAPT 40%
**Key references:**
- ADAPT: NanoClaw `task-scheduler.ts`
- ADAPT: `marketing_skills_repo/` — workflow patterns
- BUILD: NanoClaw-specific workflow engine

### TZ-0.7: Quality Gate + Integration Tests
**Sessions:** 1-2 | **Priority:** P2

**Scope:**
- CI pipeline for skill validation
- Integration test framework (skill + channel + agent)
- Quality gate checklist (auto-check before deploy)

**Verdict mix:** ADAPT 40%
**Key references:**
- COPY: NanoClaw existing test suite (436 tests, vitest)
- ADAPT: `antropic_docs/claude-code` — testing patterns

---

## Phase 1: Topology — Деталі

### Вердикти по компонентах

| Область | Компоненти | COPY | ADAPT | BUILD | DEFER |
|---------|-----------|------|-------|-------|-------|
| Ownership Model | 12 | 3 | 5 | 1 | 3 |
| 4-Layer Architecture | 10 | 2 | 4 | 2 | 2 |
| Canonical Store | 15 | 3 | 6 | 3 | 3 |
| Information Flows | 18 | 2 | 7 | 5 | 4 |
| Context Modules | 12 | 1 | 5 | 2 | 4 |

### TZ-1.1: Ownership Model + Group Registration
**Sessions:** 2-3 | **Priority:** P0

**Scope:**
- 1:1:N model (1 user → 1 company → N groups)
- Group registration flow (HITL: owner confirms → bot discovers → store metadata)
- Company profile schema (SQLite)
- User authentication + authorization

**Verdict mix:** ADAPT 55% — NanoClaw вже має базову модель
**Key references:**
- COPY: `nanoclaw_main_REPO_test/src/channels/telegram.ts` — existing group handling
- ADAPT: `nanoclaw_main_REPO_test/src/store/` — SQLite store patterns
- BUILD: Multi-group isolation logic

### TZ-1.2: 4-Layer Architecture + Canonical Store
**Sessions:** 2-3 | **Priority:** P0

**Scope:**
- Layer separation: Infra → Core → Channels → Skills
- Canonical store schema (companies, groups, skills, tasks, memory)
- Migration system for schema evolution
- Service registry (which components exist, their state)

**Verdict mix:** ADAPT 50%
**Key references:**
- COPY: NanoClaw existing `better-sqlite3` setup
- ADAPT: NanoClaw `src/store/` patterns
- BUILD: Full canonical schema for marketing OS
- BUILD: Service registry

### TZ-1.3: Core Information Flows
**Sessions:** 2-3 | **Priority:** P0

**Scope:**
- Flow A: Discovery (new group → scan → store metadata)
- Flow B: Inbound (message → parse → route to skill → execute)
- Flow C: Outbound (skill output → format → send via channel)
- Flow D: Command (explicit command → parse → dispatch)

**Verdict mix:** ADAPT 55%
**Key references:**
- ADAPT: NanoClaw existing message routing pipeline
- ADAPT: claudegram (message → claude → response flow)
- BUILD: Skill-based routing (no existing pattern)

### TZ-1.4: Forum Thread Hierarchy + Context Modules
**Sessions:** 2-3 | **Priority:** P1

**Scope:**
- Topic-per-project mapping (forum topics ↔ marketing tasks)
- Context module schema (what context each skill needs)
- Thread routing rules

**Verdict mix:** BUILD 50% — forum routing = нова архітектура
**Key references:**
- BUILD: Forum-to-project mapping (no reference)
- ADAPT: NanoClaw discovery pipeline (group scanning)
- BUILD: Context module definitions

### TZ-1.5: Extended Flows + Session Transfer
**Sessions:** 2-3 | **Priority:** P2

**Scope:**
- Flow E: HITL (human approval loops)
- Flow F: Background (scheduled, async tasks)
- Session transfer between channels
- Auxiliary runtime support

**Verdict mix:** BUILD 40%, DEFER 30%
**Key references:**
- ADAPT: linuz90 `ask-user.ts` (HITL pattern)
- ADAPT: NanoClaw `task-scheduler.ts`
- DEFER: Session transfer, auxiliary runtimes

---

## Phase 2: Telegram Bot API — Деталі

### Зведена таблиця по категоріях (Bot API 9.3)

| Category | Components | COPY | ADAPT | BUILD | DEFER |
|----------|-----------|------|-------|-------|-------|
| A. Messaging | 12 | 4 | 3 | 2 | 3 |
| B. Inline Keyboards | 8 | 1 | 3 | 2 | 2 |
| C. Reply Keyboards | 3 | 1 | 0 | 0 | 2 |
| D. Groups & Supergroups | 8 | 2 | 3 | 0 | 3 |
| E. Forums | 4 | 0 | 0 | 3 | 1 |
| F. Channels (Marketing) | 8 | 2 | 3 | 1 | 2 |
| G. Stories | 4 | 0 | 0 | 2 | 2 |
| H. Payments | 6 | 0 | 3 | 2 | 1 |
| I. Mini Apps | 3 | 0 | 0 | 0 | 3 |
| J. Business Features | 5 | 0 | 1 | 2 | 2 |
| K. Inline Mode | 2 | 0 | 0 | 0 | 2 |
| L. Moderation | 7 | 2 | 2 | 0 | 3 |
| M. Webhooks | 4 | 3 | 0 | 0 | 1 |
| N. Channel Adaptor | 4 | 0 | 3 | 1 | 0 |

### TZ-2.1: Core Bot Runtime
**Sessions:** 2-3 | **Priority:** P0

**Scope:** sendMessage + MarkdownV2, webhooks, HITL basic buttons, setMyCommands, group model, allowed updates filter
**Verdict:** 70% COPY — grammY + NanoClaw вже є
**References:** nanoclaw telegram.ts, claudegram, grammY

### TZ-2.2: Channel Adaptor Engine
**Sessions:** 2-3 | **Priority:** P0

**Scope:** Chunking (>4096 chars), MarkdownV2 conversion, rate limiter, media groups, reply keyboards, forward/copy
**Verdict:** 70% ADAPT
**References:** claudegram (chunking), RichardAtCT (rate_limiter.py), ductor (streaming)

### TZ-2.3: HITL & Streaming
**Sessions:** 2-3 | **Priority:** P0

**Scope:** sendMessageDraft streaming (9.3), colored buttons (9.3), wizard flow, callback routing + timeout, standard HITL layouts
**Verdict:** 50% BUILD — streaming + wizard flow потребує нової архітектури
**References:** linuz90 ask-user.ts, Angusstone7 keyboards, ductor streaming.py

### TZ-2.4: Voice I/O Pipeline
**Sessions:** 1-2 | **Priority:** P1

**Scope:** Voice input (STT via Whisper), Voice output (TTS via Piper/ElevenLabs), hybrid mode
**Verdict:** 70% COPY
**References:** claudegram (Groq Whisper), kai (piper_tts.py, local whisper.cpp)

### TZ-2.5: Forums & Group Management
**Sessions:** 2-3 | **Priority:** P1

**Scope:** Forum topics CRUD, message_thread_id routing, forum-manager skill, group metadata, pin messages
**Verdict:** 70% BUILD — forum automation = нова територія
**References:** grammY API, telegram-mcp (chigwell)

### TZ-2.6: Moderation & Security
**Sessions:** 1-2 | **Priority:** P1

**Scope:** ban/restrict, anti-spam, join request moderation, invite links analytics, group-moderator skill
**Verdict:** 60% ADAPT
**References:** RichardAtCT security/validators.py, telegram-mcp (chigwell)

### TZ-2.7: Channel Publishing
**Sessions:** 2-3 | **Priority:** P1

**Scope:** Channel posts, scheduled publishing, reactions tracking, analytics, channel-manager skill, telegram-mcp connector
**Verdict:** 60% ADAPT
**References:** social-media-mcp, marketing-mcp, telegram-mcp (chigwell)

### TZ-2.8: Advanced — Payments, Stories, Business
**Sessions:** 2-3 | **Priority:** P2

**Scope:** Stars invoices, paid media, Stories API, business features, Channel DMs, quick replies
**Verdict:** 60% BUILD — новий Bot API 9.x, мало референсів
**References:** grammY payments docs

---

## Phase 2.5: MTProto Userbot — Деталі

### Зведена таблиця по категоріях

| Category | Components | COPY | ADAPT | BUILD | DEFER |
|----------|-----------|------|-------|-------|-------|
| Infrastructure | 13 | 0 | 3 | 8 | 2 |
| A. History & Search | 8 | 1 | 6 | 1 | 0 |
| B. Members & Contacts | 7 | 2 | 2 | 2 | 1 |
| C. Groups/Channels Mgmt | 11 | 1 | 6 | 3 | 1 |
| D. Content Publishing | 11 | 2 | 5 | 3 | 1 |
| E. Media & Files | 4 | 1 | 2 | 0 | 1 |
| F. Account & Profile | 7 | 0 | 2 | 3 | 2 |
| G. Intelligence | 7 | 0 | 1 | 4 | 2 |
| H. User-Specific | 6 | 2 | 2 | 0 | 2 |
| Discovery Pipeline | 3 | 1 | 1 | 1 | 0 |

### TZ-2.5.1: GramJS Core Client
**Sessions:** 2-3 | **Priority:** P1

**Scope:** telegram-user.ts: GramJS init, auth flow (phone/code/2FA via HITL bot), StringSession AES-256-GCM storage, connection lifecycle
**Verdict:** 60% BUILD — HITL auth flow + encrypted storage = нове
**References:** telegram-mcp chigwell (Telethon concept), antongsm (dual API), GramJS docs

### TZ-2.5.2: Anti-Ban Engine
**Sessions:** 2-3 | **Priority:** P1

**Scope:** anti-ban.ts: rate limiter per-method, risk classifier (GREEN/YELLOW/RED/BLOCKED), FloodWait handler, human-like delays (typing, readHistory), daily budgets
**Verdict:** 70% BUILD — найвищий технічний ризик
**References:** RichardAtCT rate_limiter.py (token bucket pattern)

### TZ-2.5.3: Channel Coordinator
**Sessions:** 2-3 | **Priority:** P1

**Scope:** channel-coordinator.ts: Bot vs User routing rules, event dedup, graceful degradation (User→Bot fallback), request queue
**Verdict:** 80% BUILD — унікальна архітектура
**References:** Немає прямого аналогу

### TZ-2.5.4: IPC Extension
**Sessions:** 2-3 | **Priority:** P1

**Scope:** IPC protocol extension: user-requests/responses dirs, 15 tg_* MCP tools, authorization per group (main=all, non-main=read-only)
**Verdict:** 50% BUILD + 50% ADAPT
**References:** nanoclaw ipc.ts (existing IPC protocol)

### TZ-2.5.5: History & Search
**Sessions:** 2-3 | **Priority:** P1

**Scope:** getHistory, searchMessages (per chat + global), getDialogs, getSavedDialogs, getPinnedMessages, pagination engine
**Verdict:** 70% ADAPT
**References:** telegram-mcp chigwell (Telethon), GramJS docs

### TZ-2.5.6 — TZ-2.5.12: (P2, деталі в Phase 2.5 компонентній таблиці вище)

---

## Phase 3: Claude Platform — Деталі

### Зведена таблиця

| Область | Компоненти | COPY | ADAPT | BUILD | DEFER |
|---------|-----------|------|-------|-------|-------|
| API Integration | 8 | 2 | 4 | 2 | 0 |
| Model Selection | 6 | 0 | 2 | 3 | 1 |
| Caching | 5 | 1 | 2 | 2 | 0 |
| Batch/Background | 4 | 0 | 2 | 1 | 1 |
| MCP Integration | 4 | 1 | 2 | 1 | 0 |
| Multi-Agent | 3 | 0 | 1 | 2 | 0 |

### TZ-3.1: Claude API Core Integration
**Sessions:** 2-3 | **Priority:** P0

**Scope:** Messages API client (streaming), system prompt management, tool use integration, error handling + retry, token counting
**Verdict:** 60% ADAPT
**References:** claudegram (Claude API), claude-cookbooks, Anthropic SDK docs

### TZ-3.2: Model Selection + Cost Framework
**Sessions:** 2-3 | **Priority:** P1

**Scope:** Model matrix (Haiku/Sonnet/Opus routing), task→model mapping rules, cost tracking per company, budget alerts
**Verdict:** 60% BUILD
**References:** claudegram (basic model selection), claude-cookbooks (model comparison)

### TZ-3.3: Caching & Context Budget
**Sessions:** 2-3 | **Priority:** P1

**Scope:** Prompt caching (Anthropic beta), context window budget management, conversation pruning strategy
**Verdict:** 50% BUILD
**References:** Anthropic caching docs, claude-cookbooks

### TZ-3.4 — TZ-3.6: (P2, batch API, MCP integration, multi-agent orchestration)

---

## Phase 4: Information Flows — Деталі

### Зведена таблиця

| Область | Компоненти | COPY | ADAPT | BUILD | DEFER |
|---------|-----------|------|-------|-------|-------|
| Core Flows (A-D) | 16 | 0 | 8 | 6 | 2 |
| Extended Flows (E-G) | 12 | 0 | 5 | 5 | 2 |
| Specialty Flows (H-J) | 9 | 0 | 2 | 5 | 2 |
| Memory System | 8 | 0 | 3 | 4 | 1 |
| HITL Convention | 6 | 0 | 2 | 2 | 2 |

### TZ-4.1: Core Flows Engine (A-D)
**Sessions:** 2-3 | **Priority:** P0

**Scope:**
- Flow A: Discovery (trigger: new group → scan → store)
- Flow B: Inbound Message Processing (parse → classify → route → execute)
- Flow C: Outbound Response (format → chunk → send)
- Flow D: Command Dispatch (explicit /command → handler)
**Verdict:** 55% ADAPT
**References:** NanoClaw existing pipeline, claudegram message flow

### TZ-4.2: Extended Flows (E-G)
**Sessions:** 2-3 | **Priority:** P1

**Scope:**
- Flow E: HITL Loop (request approval → wait → process response)
- Flow F: Background Task (schedule → execute → report)
- Flow G: Notification (event → format → deliver)
**Verdict:** 50% BUILD
**References:** linuz90 ask-user.ts (HITL), NanoClaw task-scheduler.ts

### TZ-4.3: 3-Level Memory System
**Sessions:** 2-3 | **Priority:** P1

**Scope:**
- L0: Working memory (conversation context, active task state)
- L1: Session memory (cross-session per company/group)
- L2: Long-term memory (knowledge base, learned preferences)
- Memory consolidation pipeline (L0→L1→L2)
**Verdict:** 70% BUILD
**References:** kai (local memory implementation), claude-cookbooks (memory patterns)

### TZ-4.4 — TZ-4.8: (P2, specialty flows, knowledge graph, HITL convention, cross-session state, automated workflows)

---

## Phase 5: Deployment — Деталі

### Зведена таблиця

| Область | Компоненти | COPY | ADAPT | BUILD | DEFER |
|---------|-----------|------|-------|-------|-------|
| Docker Base | 10 | 5 | 3 | 1 | 1 |
| Security (22 items) | 15 | 3 | 7 | 4 | 1 |
| Monitoring | 8 | 1 | 3 | 2 | 2 |
| Scaling | 10 | 2 | 3 | 3 | 2 |

### TZ-5.1: Docker Deployment Base
**Sessions:** 2-3 | **Priority:** P0

**Scope:** Dockerfile, docker-compose, volume mounts, env management, health checks, container isolation (existing NanoClaw)
**Verdict:** 70% COPY — NanoClaw вже має container isolation
**References:** nanoclaw_main_REPO_test (container setup), nanoclaw_reserch_arhitecture

### TZ-5.2: Security Hardening
**Sessions:** 2-3 | **Priority:** P1

**Scope:** 22-item security checklist (secrets management, TLS, input validation, rate limiting, audit log, backup)
**Verdict:** 55% ADAPT
**References:** RichardAtCT (5-layer security), nanoclaw_reserch_arhitecture (container security analysis)

### TZ-5.3 — TZ-5.4: (P2, monitoring + scaling)

---

## Top 10 Reference Repos (за частотою використання)

| # | Repo | Phases | Components Referenced | Primary Value |
|---|------|--------|----------------------|---------------|
| 1 | **telegram-mcp (chigwell)** | 2, 2.5 | 27+ | Telethon API patterns, 25+ tools |
| 2 | **nanoclaw_main_REPO_test** | 0-5 | 20+ | Battle-tested core, 436 tests |
| 3 | **claudegram (NachoSEO)** | 2, 3 | 15+ | Claude+TG integration, streaming |
| 4 | **Anthropic plugins (18)** | 0, 3 | 15+ | Skill structure, system prompts |
| 5 | **RichardAtCT** | 2, 2.5, 5 | 12+ | 5-layer security, rate limiting |
| 6 | **My_skill_and_insite** | 0, 1 | 10+ | Rubric, MECE Matrix, Marketing Chain |
| 7 | **GramJS (direct)** | 2.5 | 20+ | MTProto API reference |
| 8 | **kai (Telegram voice bot)** | 2, 4 | 6+ | Voice pipeline, local memory |
| 9 | **linuz90** | 2, 4 | 5+ | HITL ask-user MCP pattern |
| 10 | **Analysis_reports_md** | 0, 1 | 7+ | MECE analysis methodology |

---

## Ризики та мітігація

| Ризик | TZ | Імпакт | Мітігація |
|-------|-----|--------|-----------|
| Anti-ban engine (бан акаунту) | TZ-2.5.2 | CRITICAL | Conservative rate limits, HITL for HIGH risk, daily budgets |
| Phase 4 = 43% BUILD | TZ-4.* | HIGH | Інкрементальна розробка, MVP flows first |
| Bot API 9.3 streaming нестабільний | TZ-2.3 | MEDIUM | Fallback на sendChatAction("typing") |
| GramJS менш зрілий ніж Telethon | TZ-2.5.1 | MEDIUM | mtcute як backup, active community |
| Channel Coordinator складність | TZ-2.5.3 | HIGH | Bot-first fallback, поступова інтеграція |
| Memory system scale | TZ-4.3 | MEDIUM | Start with L0+L1, L2 пізніше |
| Scope creep (50 TZ!) | ALL | HIGH | Strict P0→P1→P2 execution order |

---

## Execution Waves (рекомендований порядок)

### Wave 1: Foundation (P0 — тижні 1-8)
```
TZ-0.1 (Skill Standard) ──→ TZ-0.2 (Evaluation) ──→ TZ-0.3 (Templates)
         │
         ├──→ TZ-1.1 (Ownership) ──→ TZ-1.2 (Architecture) ──→ TZ-1.3 (Core Flows)
         │                                    │
         │                                    ├──→ TZ-2.1 (Bot Runtime) ──→ TZ-2.2 (Adaptor)
         │                                    │
         │                                    ├──→ TZ-3.1 (Claude API)
         │                                    │
         │                                    └──→ TZ-5.1 (Docker Base)
```

### Wave 2: Core Features (P1 — тижні 9-18)
```
TZ-2.3 (HITL) ──→ TZ-2.5 (Forums) ──→ TZ-2.7 (Channels)
TZ-2.4 (Voice)
TZ-2.5.1 (GramJS) ──→ TZ-2.5.2 (Anti-Ban) ──→ TZ-2.5.3 (Coordinator)
TZ-3.2 (Models) ──→ TZ-3.3 (Caching)
TZ-4.1 (Core Flows) ──→ TZ-4.2 (Extended) ──→ TZ-4.3 (Memory)
TZ-5.2 (Security)
```

### Wave 3: Expansion (P2 — тижні 19-28)
```
TZ-2.5.4-12, TZ-2.8, TZ-3.4-6, TZ-4.4-8, TZ-5.3-4, TZ-0.4-7, TZ-1.4-5
```

---

_Generated: 2026-03-01 | Source: architecture docs (phases 0-5 + 2.5) + pattern-inventory.md (240+ items)_
_Next step: STEP 3 — написання детальних ТЗ документів по одному_
