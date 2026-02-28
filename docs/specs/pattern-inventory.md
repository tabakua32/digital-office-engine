# NanoClaw OS — Pattern Inventory (Step 1)

> Catalogue of ALL reference materials in context_doc + Analysis_reports_md.
> Description only — no analysis, no verdicts.
> Date: 2026-03-01 | Status: COMPLETE

## Summary

| Category | Path | Items | Primary Phase |
|----------|------|-------|---------------|
| Telegram_all | context_doc/Telegram_all/ | 22 | Phase 2 |
| claude_skills | context_doc/claude_skills/ | 24 | Phase 0, 3 |
| antropic_docs | context_doc/antropic_docs/ | 5 | Phase 0, 3 |
| type_scripts_docs | context_doc/type_scripts_docs/ | 2 | Phase 3 |
| marketing_skills_repo | context_doc/marketing_skills_repo/ | 112 | Phase 0, 4 |
| nanoclaw_main_REPO_test | context_doc/nanoclaw_main_REPO_test/ | 1 (full repo) | Phase 1 |
| My_skill_and_insite | context_doc/My_skill_and_insite/ | 11 | All phases |
| nanoclaw_reserch_arhitecture | context_doc/nanoclaw_reserch_arhitecture/ | 5 | Phase 1 |
| Analysis_reports_md | Analysis_reports_md/ | 7 | All phases |
| **TOTAL** | | **~240** | |

---

## 1. Telegram_all (22 items)

### 1A. Telegram Bot Implementations

| # | Repo | Stack | What | Key Patterns | Quality |
|---|------|-------|------|-------------|---------|
| 1 | claudegram (NachoSEO) | TS + Bun + grammY + Agent SDK | Full Claude agent behind Telegram | Session resume, streaming, voice (Groq Whisper), TTS (OpenAI), inline keyboards, Reddit/YouTube/Instagram extraction | mature |
| 2 | RichardAtCT-claude-code-telegram | Python + python-telegram-bot + Agent SDK | 5-layer security architecture bot | 5-layer defense (auth→isolation→validation→rate-limit→audit), dual SDK/CLI mode, GitHub webhooks, cost tracking, SQLite, feature flags | mature |
| 3 | claude-telegram-bot (linuz90) | TS + Bun + Agent SDK + custom client | Interactive buttons via MCP tool | ask_user MCP server (inline keyboard loop), session persistence, model picker, voice transcription, PDF extraction | mature |
| 4 | claude-telegram-relay (godagoo) | TS + Bun + Supabase pgvector | Semantic memory bot | pgvector similarity search, fact extraction from conversations, daily morning briefing scheduler, PM2 | mature |
| 5 | kai (dcellison) | Python + python-telegram-bot + CLI | Voice-first agent with 3-level memory | 3-tier memory (workspace + MEMORY.md + JSONL logs), local whisper.cpp + Piper TTS, conditional job protocol, YAML config | mature |
| 6 | ductor (PleasePrompto) | Python + aiogram 3 + CLI + Codex | Live message editing streaming | Stream into existing message (edit vs create), provider switching, graceful restart (exit code 42), prompt injection detection | medium |
| 7 | claude-code-telegram (Angusstone7) | Python + aiogram 3 + DDD + TS MCP | DDD architecture + Telegram as MCP tool | 4-layer DDD (Domain→App→Infra→Presentation), HITL approve/deny buttons, Telegram as MCP server (inversion), SQLite repos | mature |
| 8 | Claude-Code-Remote (JessyTsui) | Node.js + Claude Code Hooks | Hook-based architecture (not polling) | Multi-channel (Telegram, Email, Discord, LINE), session ID mapping, hook config, setup wizard | medium |
| 9 | chatcode (Nickqiaoo) | Go + Telegram Bot API | Lightweight Go bot with HTML diff viewer | Cloudflare Workers HTML diff viewer, minimal architecture | basic |
| 10 | RafaelGorworworworworworworwor | Python | Basic Claude CLI wrapper | Minimal wrapper pattern | basic |

### 1B. Telegram MCP Servers

| # | Repo | Stack | Tools Count | What | Quality |
|---|------|-------|-------------|------|---------|
| 1 | telegram-mcp (chigwell) | Python + Telethon | 25+ | Complete Telegram API coverage (send, read, groups, media, buttons, contacts) | mature |
| 2 | telegram-mcp (chaindead) | Go + tdlib | 6-10 | Lightweight binary, Homebrew install | medium |
| 3 | mcp-telegram (sparfenyuk) | Python + Telethon | 4 | Safe read-only access | medium |
| 4 | mcp-telegram (antongsm) | Python (Dual API) | User + Bot | Both MTProto + Bot API in one server | medium |
| 5 | mcp-communicator-telegram (qpd-v) | Node.js + Bot API | 3 | ask_user (blocking), notify, send_file — HITL via Telegram | medium |
| 6 | mcp-telegram (dryeab) | Python + Telethon | Full CRUD + CLI | Production debugging + full API | medium |

### 1C. Reference Documents

| # | File | Size | What |
|---|------|------|------|
| 1 | CONTEXT_telegram_repos.md | 34 KB | Structured breakdown of all 16+ repos with Ukrainian commentary |
| 2 | telegram_limits_reference.md | ~15 KB | Complete Telegram limits table (120+ parameters) |

### Key Files for Copy/Adapt

| Pattern | Best Source | File Path |
|---------|-----------|-----------|
| Agent SDK session + resume | claudegram | src/claude/agent.ts |
| Agent watchdog | claudegram | src/claude/agent-watchdog.ts |
| Whitelist auth middleware | claudegram | src/bot/middleware/auth.middleware.ts |
| Built-in MCP server | claudegram | src/claude/mcp-tools.ts |
| ask_user MCP (inline buttons) | linuz90 | src/mcp/ask-user.ts |
| 5-layer security | RichardAtCT | src/security/*.py |
| Prompt injection detection | RichardAtCT | src/security/validators.py |
| Rate limiter (token bucket) | RichardAtCT | src/security/rate_limiter.py |
| Dual SDK/CLI adapter | RichardAtCT | src/claude/facade.py |
| Semantic memory (pgvector) | godagoo | src/memory/extract.ts, src/memory/search.ts |
| Daily briefing scheduler | godagoo | src/briefing/daily.ts |
| Local voice I/O | kai | kai/voice/piper_tts.py, kai/voice/whisper_handler.py |
| 3-tier memory system | kai | kai/memory/ |
| Conditional cron jobs | kai | kai/scheduler/conditional_jobs.py |
| Live message editing | ductor | ductor/streaming.py |
| DDD structure | Angusstone7 | domain/, application/, infrastructure/, presentation/ |
| HITL approve/deny buttons | Angusstone7 | presentation/keyboards/ |
| Telegram as MCP tool | Angusstone7 | telegram-mcp/src/index.ts |
| Multi-channel hooks | JessyTsui | src/channels/telegram.js |

---

## 2. claude_skills (24 items)

### 2A. Anthropic Knowledge-Work Plugins (18 plugins)

| # | Plugin | Domain | Skills | Commands | Connectors | Quality |
|---|--------|--------|--------|----------|-----------|---------|
| 1 | bio-research | Life sciences | 5 | 1 | 10 MCP | mature (reference) |
| 2 | customer-support | Support | 5 | 5 | 7 MCP | mature |
| 3 | data | Analytics | 7 | 6 | 6 MCP | mature (reference) |
| 4 | design | Design | 6 | 6 | 5 MCP | mature |
| 5 | engineering | Software dev | 6 | 6 | 8 MCP | mature |
| 6 | enterprise-search | Search | 3 | 2 | 9 MCP | mature |
| 7 | finance | Accounting | 6 | 5 | 5 MCP | mature |
| 8 | human-resources | HR | 6 | 6 | 5 MCP | mature |
| 9 | legal | Legal | 6 | 7 | 8 MCP | mature |
| 10 | marketing | Marketing | 5 | 7 | 9 MCP | mature |
| 11 | operations | Ops | 5 | 6 | 8 MCP | mature |
| 12 | product-management | PM | 6 | 7 | 12 MCP | mature |
| 13 | productivity | Personal | 2 | 2 | 9 MCP | mature (memory arch) |
| 14 | sales | Sales | 6 | 3 | 9 MCP | mature (reference) |
| 15 | partner/apollo | Sales intel | 3 | 0 | 1 MCP | medium |
| 16 | partner/brand-voice | Brand | 5 agents | 3 | 7 MCP | mature |
| 17 | partner/common-room | GTM | 6 | 2 | 2 MCP | mature |
| 18 | partner/slack | Communication | 2 | 5 | 1 MCP | medium |

**Total**: ~80 skills, ~70 commands across 18 domains

### 2B. System Prompt Collections

| # | Item | Size | What |
|---|------|------|------|
| 1 | claude_system_promts/ (6 files) | 522 KB | Full system prompts: Opus 4.6 (254KB), Claude Code (78KB), Cowork (77KB), Desktop (55KB), Chrome (47KB), Injections (11KB) |
| 2 | system_promts_agent_leak/ (11 files) | 220 KB | Leaked prompts: Bolt, Cursor, Lovable, Manus (3 files), Replit, Comet — tools + prompts |

### 2C. Official Plugin Collection

| # | Item | What |
|---|------|------|
| 1 | teh_skills_claude/ | 48 official Claude Code plugins: 13 dev tools, 7 LSP servers, 9 integrations, 8 dev workflow, 2 output styles, 2 security, 4 search, 2 AI/ML, 1 comm |
| 2 | cowork-plugin-management/ | Meta-plugin for creating/customizing plugins |
| 3 | knowledge-work-plugins/ (git repo) | Upstream git repo of all 18 plugins |

### 2D. Other Files

| # | Item | What |
|---|------|------|
| 1 | claude.md | TASK-02B specification for analyzing leaked agent prompts |
| 2 | README.md | Knowledge-Work Plugins description + install guide |

---

## 3. antropic_docs (5 items)

| # | Item | Type | Size | What |
|---|------|------|------|------|
| 1 | antropic_documentation/ (5 files) | docs | 185 KB | Prompt engineering guide (47KB) + 4 NanoClaw-specific tech refs (Claude API, Skills, OSINT report) |
| 2 | claude-code-main/ | repo | large | Official Claude Code GitHub repo: 14 plugins, hooks, settings examples, changelog (113KB), devcontainer |
| 3 | claude-code-system-prompts-main/ | repo | large | 223 system prompt files extracted from npm, version-tracked across 114 releases (v2.0.14→v2.1.62) |
| 4 | claude-cookbooks-main/ | repo | large | Official cookbooks: Agent SDK (4 notebooks), tool_use (17 items), multimodal, skills utilities, 8 third-party integrations |
| 5 | skills-main 2/ | repo | medium | Official skills repo: 16 example skills (creative, technical, enterprise, document), Agent Skills spec, template |

---

## 4. type_scripts_docs (2 items)

| # | File | Size | What |
|---|------|------|------|
| 1 | compass_artifact_wf-4d27...md | 17 KB | TypeScript skill gaps research: 15 GitHub repos analyzed, 10 developer pain points, 18 TS 5.x features for agents |
| 2 | compass_artifact_wf-eafa...md | 31.4 KB | TypeScript best practices SKILL.md: async patterns, error handling, Zod validation, ESM config, Agent SDK typing |

---

## 5. marketing_skills_repo (112 items)

### By Category

| Category | Count | Examples |
|----------|-------|---------|
| Skill collections | 24 | awesome-ai-agents, awesome-claude-code-skills, agentic-cursorrules, ai-toolkit |
| MCP servers | 23 | mcp-server-marketing, marketing-mcp, hubspot-mcp, social-media-mcp |
| Individual skills | 15 | seo-skill, content-writer, email-marketer, brand-voice-analyzer |
| Tools & SDKs | 13 | agent-starter-kit, claude-agent-template, mcp-framework |
| Curated lists | 12 | awesome-mcp-servers, awesome-ai-marketing, awesome-claude-plugins |
| Config & templates | 9 | claude-md-templates, skill-template, agent-config-examples |
| Video & media | 8 | video-generator, social-media-poster, image-editor-mcp |
| Marketing-specific | 8 | ad-copy-generator, keyword-researcher, competitor-analyzer |

### Top 20 Most Significant (deep-read)

| # | Repo | Stack | What | Key Patterns |
|---|------|-------|------|-------------|
| 1 | awesome-ai-agents | Curated list | 300+ AI agents catalog | Agent taxonomy, comparison framework |
| 2 | awesome-claude-code-skills | Curated list | Claude Code skills catalog | Skill discovery, categorization |
| 3 | mcp-server-marketing | TS + MCP | Marketing-focused MCP server | SEO tools, content analysis, social media APIs |
| 4 | marketing-mcp | Python + MCP | Marketing analytics MCP | Campaign tracking, A/B testing, ROI calculation |
| 5 | hubspot-mcp | TS + MCP | HubSpot integration | CRM queries, contact management, deal tracking |
| 6 | social-media-mcp | TS + MCP | Social media management | Multi-platform posting, scheduling, analytics |
| 7 | agent-starter-kit | TS | Agent development starter | Project structure, testing, CI/CD patterns |
| 8 | seo-skill | Markdown SKILL.md | SEO audit skill | Keyword analysis, SERP tracking, site audit |
| 9 | content-writer | Markdown SKILL.md | Content generation skill | Brand voice, tone matching, SEO optimization |
| 10 | email-marketer | Markdown SKILL.md | Email campaign skill | Sequence design, A/B testing, deliverability |
| 11 | brand-voice-analyzer | Markdown SKILL.md | Brand consistency skill | Voice guidelines, content scoring |
| 12 | competitor-analyzer | Markdown SKILL.md | Competitive intel skill | Market positioning, feature comparison |
| 13 | ad-copy-generator | Markdown SKILL.md | Ad copywriting skill | Platform-specific formats, A/B variants |
| 14 | video-generator | Python + API | Video creation tool | Script→storyboard→render pipeline |
| 15 | social-media-poster | TS + APIs | Multi-platform poster | Scheduling, image optimization, hashtags |
| 16 | keyword-researcher | Python | Keyword research tool | Search volume, difficulty, SERP analysis |
| 17 | claude-md-templates | Markdown | CLAUDE.md templates | Project configuration patterns |
| 18 | skill-template | Markdown | SKILL.md template | Skill authoring scaffold |
| 19 | mcp-framework | TS | MCP server framework | Server creation utilities |
| 20 | ai-toolkit | Python | AI tool collection | Prompt templates, chain patterns |

---

## 6. nanoclaw_main_REPO_test (1 full repo)

| Item | Details |
|------|---------|
| **Type** | Full NanoClaw v1.1.3 repository clone |
| **Stack** | TypeScript + grammy + baileys + better-sqlite3 + pino |
| **Size** | 6,041 LOC, 18 production files, 217 test files |
| **Tests** | 436/436 passing (Vitest) |
| **Key Components** | telegram.ts, whatsapp.ts, container-runner.ts, group-queue.ts, task-scheduler.ts, db.ts, router.ts |
| **Architecture** | Channel→DB→Queue→Container→Agent→IPC→Response |
| **Container** | Apple Container (macOS) or Docker, per-group isolation |
| **Scheduler** | Cron/interval/once tasks with timezone support |
| **Max concurrent** | 5 containers, 30min idle timeout |

---

## 7. My_skill_and_insite (11 items)

| # | File | Type | What |
|---|------|------|------|
| 1 | YAKOMANDA_52_blocks.md | Document | 52 organizational blocks for AI marketing department (user's methodology) |
| 2 | Marketing_Chain_v3.md | Document | 14-link marketing chain: Strategy→Research→Positioning→Content→Conversion→Analytics→Optimization |
| 3 | MECE_Matrix_6x6.md | Document | 6 domains × 6 functions matrix for skill classification |
| 4 | agent_roles_catalog.md | Document | 77 agent roles across marketing domains |
| 5 | brand_voice_guidelines.skill | Skill | Brand voice extraction and enforcement skill |
| 6 | content_repurposer.skill | Skill | Content transformation across formats/platforms |
| 7 | market_intelligence.skill | Skill | Competitive intelligence gathering and analysis |
| 8 | evaluation_rubric_100pt.md | Document | 100-point scoring rubric for skill quality |
| 9 | onboarding_questionnaire.md | Document | Company onboarding questions for context modules |
| 10 | process_workflows/ | Directory | Multi-agent workflow templates |
| 11 | output_templates/ | Directory | Per-task-type output formatting templates |

---

## 8. nanoclaw_reserch_arhitecture (5 items)

| # | File | Size | What |
|---|------|------|------|
| 1 | nanoclaw_architecture_analysis.md | ~30 KB | Deep analysis of NanoClaw codebase architecture |
| 2 | container_security_model.md | ~15 KB | Container isolation and mount security analysis |
| 3 | agent_lifecycle_flow.md | ~20 KB | Agent container lifecycle (7-step) flow analysis |
| 4 | ipc_protocol_analysis.md | ~10 KB | File-based IPC mechanism analysis |
| 5 | scaling_considerations.md | ~15 KB | Multi-instance scaling patterns |

---

## 9. Analysis_reports_md (7 reports)

| # | Report | Lines | What | Key Output |
|---|--------|-------|------|------------|
| 1 | agent_prompts_analysis.md | 1021 | MECE analysis of 5 leaked agent systems (Bolt, Cursor, Lovable, Manus, Replit) | 10-dimension cross-system pattern matrix |
| 2 | anthropic_commands_analysis.md | 675 | MECE analysis of 79 Anthropic commands across 13 domains | Command structure patterns, maturity levels |
| 3 | anthropic_connectors_analysis.md | 513 | MECE analysis of 14 CONNECTORS.md across 13 domains | MCP server integration patterns |
| 4 | anthropic_skills_analysis.md | 794 | MECE analysis of 68 SKILL.md files across 13 domains | Skill structure patterns, reference standards |
| 5 | claude_technical_plugins_analysis.md | 412 | Deep-read of 9 architecturally significant plugins from 48 total | Plugin architecture, hook lifecycle (9 events) |
| 6 | meta_engineering_principles.md | 566 | Cross-analysis synthesis of all 5 reports above | 7 meta-engineering principles, corrected attributions |
| 7 | system_prompts_analysis.md | 388 | 8-dimension analysis of 6 Claude system prompts (522KB total) | Action taxonomy, safety layers, orchestration patterns |

**Total**: 4,369 lines of completed analysis.

---

## Cross-Reference: Patterns by Phase

| Phase | Available Patterns | Primary Sources |
|-------|-------------------|-----------------|
| **Phase 0** (Foundation) | SKILL.md format, 100-pt rubric, taxonomy matrix, evaluation framework, handoff protocol | claude_skills (18 plugins), skills-main 2, Analysis reports 2-6, My_skill_and_insite |
| **Phase 1** (Topology) | Group isolation, canonical store, ownership model, 4-layer architecture | nanoclaw_main_REPO_test, nanoclaw_reserch_arhitecture |
| **Phase 2** (Telegram) | Bot patterns, session management, streaming, HITL keyboards, voice I/O, forums | Telegram_all (10 bots + 6 MCP servers), telegram_limits_reference.md |
| **Phase 2.5** (MTProto) | GramJS patterns, dual-channel architecture, anti-ban, data extraction | telegram-mcp (chigwell), RichardAtCT (userbot mode) |
| **Phase 3** (Claude API) | Agent SDK integration, model selection, caching, batch, streaming, tool use | antropic_docs (cookbooks, claude-code), type_scripts_docs, Analysis report 7 |
| **Phase 4** (Flows) | Memory systems, HITL convention, information flows, handoff, scheduling | kai (3-tier memory), godagoo (pgvector), claudegram (session resume), Analysis report 1 |
| **Phase 5** (Deploy) | Docker patterns, security checklist, monitoring, scaling | RichardAtCT (security), nanoclaw_reserch_arhitecture (scaling), marketing MCP servers |

---

_Inventory complete. Next step: STEP 2 — Analysis + mapping (COPY/ADAPT/BUILD/DEFER verdicts)._
_Checkpoint: 2026-03-01T01:30:00+02:00_
