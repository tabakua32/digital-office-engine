# Pipeline State — Phase 0

> **Claude: прочитай цей файл + наступну задачу з плану і ПОЧИНАЙ ПРАЦЮВАТИ.**
> **Якщо задача має CALIBRATE — СПОЧАТКУ ПОСТАВ ПИТАННЯ ЮЗЕРУ, потім працюй.**

**Plan:** `docs/plans/2026-02-28-phase0-tracks-AB-plan-v2.md`
**Design:** `docs/plans/2026-02-28-full-roadmap-design.md`

---

## Current Task

**NEXT:** INV-1 — Full inventory scan
**Phase:** 0.1 INVENTORY
**Status:** NOT STARTED

---

## Progress

### Phase 0.1 — Inventory
| Task | Status | Output | Date |
|------|--------|--------|------|
| INV-1: Full scan | NOT STARTED | `foundation/inventory.md` | — |

### Phase 0.2 — Evaluate (each starts with CALIBRATE)
| Task | Status | Output | Date |
|------|--------|--------|------|
| EVAL-TG: Telegram | NOT STARTED | `foundation/harvest/telegram_integrations.md` | — |
| EVAL-MKT: Marketing skills | NOT STARTED | `foundation/harvest/marketing_skills.md` | — |
| EVAL-SKILLS: Claude skills | NOT STARTED | `foundation/harvest/claude_skills_format.md` | — |
| EVAL-SDK: Anthropic platform | NOT STARTED | `foundation/harvest/anthropic_platform_rules.md` | — |
| EVAL-MCP: MCP servers | NOT STARTED | `foundation/harvest/mcp_servers_assessment.md` | — |
| EVAL-YAKO: YAKOMANДА | NOT STARTED | `foundation/harvest/yakomanda_building_blocks.md` | — |
| EVAL-REPORTS: Previous analysis | NOT STARTED | `foundation/harvest/reports_validation.md` | — |

### Phase 0.3 — Synthesize
| Task | Status | Output | Date |
|------|--------|--------|------|
| SYN-1: Cross-synthesis | NOT STARTED | `foundation/meta_synthesis_v2.md` + standard + taxonomy | — |
| SYN-2: Build factory | NOT STARTED | `nanoclaw-skill-factory/` | — |
| SYN-3: Validate factory | NOT STARTED | 3-5 test artifacts | — |

### Phase 0.4 — Production
| Task | Status | Output | Date |
|------|--------|--------|------|
| PROD-TG | NOT STARTED | `skills/communication/telegram/` | — |
| PROD-MKT | NOT STARTED | `skills/marketing/` | — |
| PROD-TECH | NOT STARTED | `skills/dev-ops/` | — |
| PROD-META | NOT STARTED | `skills/meta/` | — |

### Final
| Task | Status | Output | Date |
|------|--------|--------|------|
| FINAL-1: Integration | NOT STARTED | Working NanoClaw | — |
| FINAL-2: E2E testing | NOT STARTED | Production-ready | — |

---

## Notes for Next Session
- EVAL tasks can run in parallel (2-3 at a time)
- Each EVAL starts with CALIBRATE questions — DO NOT SKIP
- User must load 5 data sources before starting (see Prerequisites in design doc)
- If context filling up mid-task: summarize → commit WIP → continue next session
