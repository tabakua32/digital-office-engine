# Phase 0: Tracks A+B Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete all analysis for Track A (Anthropic Core) and Track B (Platform) to prepare for Merge Point 1 (Standardization + Factory).

**Architecture:** Two parallel tracks. Track A runs sequentially (A1→A6) because each step builds on previous. Track B (B1-B3) is independent and can run in a parallel session. Both produce analysis documents into `foundation/analysis/`. Quality gates verify completeness before merge.

**Tech Stack:** Markdown documents, Claude analysis capabilities, existing context_doc library, Analysis_reports_md for validation.

**Design Doc:** `docs/plans/2026-02-28-full-roadmap-design.md` — source of truth for scope.

**Language:** Plans and analysis documents in Ukrainian. File names and commits in English.

---

## Prerequisites Check

### Task 0: Verify Data Sources

Before starting any track, verify user has loaded required data.

**Step 1: Check context_doc directories exist**

Run:
```bash
ls -d ../docs/context_doc/typescript_docs/ ../docs/context_doc/claude_agent_sdk/ ../docs/context_doc/claude_api_docs/ ../docs/context_doc/telegram_api/ ../docs/context_doc/telegram_mtproto/ 2>&1
```
Expected: All 5 directories exist with content.

If ANY missing → STOP. Tell user which directories to create and populate per design doc Prerequisites table:

| Source | Target |
|--------|--------|
| TypeScript handbook + lib types | `context_doc/typescript_docs/` |
| Claude Agent SDK (npm + docs) | `context_doc/claude_agent_sdk/` |
| Claude API docs | `context_doc/claude_api_docs/` |
| Telegram Bot API 9.3 | `context_doc/telegram_api/` |
| Telegram MTProto / GramJS | `context_doc/telegram_mtproto/` |

**Step 2: Verify existing context is accessible**

Run:
```bash
ls ../docs/context_doc/antropic_docs/ ../docs/context_doc/claude_skills/ ../docs/context_doc/marketing_skills_repo/ ../Analysis_reports_md/ 2>&1
```
Expected: All exist (confirmed: antropic_docs, claude_skills, marketing_skills_repo, 7 reports).

**Step 3: Create output directory structure**

Run:
```bash
mkdir -p foundation/analysis
```

**Step 4: Commit scaffold**

```bash
git add foundation/
git commit -m "chore: create foundation/analysis directory for Phase 0"
```

---

## TRACK A — Intellectual Core

> Each task produces ONE analysis document. Sequential execution: A1 → A2 → A3 → A4 → A5 → A6.
> Total: ~4-5 sessions.

---

### Task A1: Anthropic Platform Documentation Analysis (~1 session)

**Why first:** Platform constraints are the "rules of the game" — everything else must conform.

**Files:**
- Read: `../docs/context_doc/claude_agent_sdk/` (all files)
- Read: `../docs/context_doc/claude_api_docs/` (all files)
- Read: `../docs/context_doc/antropic_docs/antropic_documentation/` (key docs)
- Read: `../docs/context_doc/antropic_docs/claude-cookbooks-main/` (patterns)
- Read: `src/` (NanoClaw source, read-only — understand runtime)
- Create: `foundation/analysis/anthropic_platform_analysis.md`

**Step 1: Define analysis template**

Create `foundation/analysis/anthropic_platform_analysis.md` with this skeleton:

```markdown
# Аналіз платформи Anthropic

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Вхідні джерела:** claude_agent_sdk, claude_api_docs, antropic_documentation, cookbooks

---

## 1. Claude Agent SDK — Архітектура

### 1.1 Container Runtime
- Як контейнер запускає агентів
- IPC механізм (stdin/stdout JSON-RPC)
- Lifecycle: init → run → stop

### 1.2 Tool System
- Вбудовані tools vs custom tools
- MCP server integration
- Tool approval flow

### 1.3 Extension Points
- Hooks (PreToolUse, PostToolUse, etc.)
- Skills (.claude/skills/)
- Commands (.claude/commands/)
- Agents (.claude/agents/)

## 2. Claude API — Constraints Matrix

### 2.1 Model Matrix
| Model | Context | Max Output | Cost/1M in | Cost/1M out | Best for |
|-------|---------|-----------|------------|-------------|----------|

### 2.2 API Features
- Messages API (standard, streaming)
- Batch API (async, cost savings)
- Prompt Caching (TTL, savings)
- Extended Thinking (budget_tokens)
- Tool Use (parallel, sequential)
- Computer Use (Beta)

### 2.3 Rate Limits & Quotas
- RPM, TPM per tier
- Batch limits
- Caching constraints

## 3. Recommended Patterns

### 3.1 From Cookbooks
- [pattern]: [опис + коли використовувати]

### 3.2 From SDK Docs
- [pattern]: [опис + обмеження]

## 4. NanoClaw Runtime Compatibility

### 4.1 src/ Architecture Mapping
- channels/ → Telegram, WhatsApp handlers
- containers/ → Docker/Apple Container runner
- skills/ → skill loading mechanism
- Що можна розширювати БЕЗ зміни src/

### 4.2 Constraints for Skills
- Max file size
- Required exports
- Naming conventions
- Container mount paths

## 5. Висновки для Skill Factory

- Обов'язкові вимоги (must have)
- Рекомендації (should have)
- Обмеження (cannot do)
```

**Step 2: Read and analyze SDK documentation**

Read all files in `../docs/context_doc/claude_agent_sdk/`. Extract:
- Container architecture details
- IPC protocol specification
- Tool system mechanics
- Extension point API

Fill sections 1.1-1.3.

**Step 3: Read and analyze API documentation**

Read all files in `../docs/context_doc/claude_api_docs/`. Extract:
- Model specifications (context, output, pricing)
- API feature details
- Rate limits and constraints

Fill sections 2.1-2.3.

**Step 4: Read and analyze Cookbooks**

Read key files in `../docs/context_doc/antropic_docs/claude-cookbooks-main/`. Extract:
- Recommended patterns with code examples
- Anti-patterns and common mistakes

Fill section 3.

**Step 5: Analyze NanoClaw source (read-only)**

Read key files in `src/` to understand runtime. Map:
- How skills are loaded and executed
- Channel integration (Telegram flow)
- Container runner mechanics
- What can be extended without modifying src/

Fill section 4.

**Step 6: Write conclusions for Factory**

Based on sections 1-4, synthesize what the Skill Factory MUST know. Fill section 5.

**Step 7: Quality gate**

Verify document:
- [ ] All 5 sections filled (no TODOs or placeholders)
- [ ] Model matrix has ≥3 models with real data
- [ ] ≥5 recommended patterns extracted
- [ ] NanoClaw extension points clearly mapped
- [ ] Conclusions section has ≥3 must-haves, ≥3 recommendations, ≥3 constraints

**Step 8: Commit**

```bash
git add foundation/analysis/anthropic_platform_analysis.md
git commit -m "docs(phase0): A1 — Anthropic platform analysis"
```

---

### Task A2: Claude System Prompt Analysis (~0.5 session)

**Depends on:** A1 (need platform understanding to interpret prompts correctly).

**Files:**
- Read: `../docs/context_doc/antropic_docs/claude-code-system-prompts-main/`
- Read: `../docs/context_doc/claude_skills/claude_system_promts/`
- Read: `foundation/analysis/anthropic_platform_analysis.md` (A1 output)
- Compare: `../Analysis_reports_md/system_prompts_analysis.md` (existing report)
- Create: `foundation/analysis/system_prompt_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз системних промптів Claude

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Залежності:** A1 (anthropic_platform_analysis.md)

---

## 1. Базові знання Claude ("знає з народження")

### 1.1 Safety & Policy Blocks
- Які обмеження вбудовані
- Що НЕ МОЖНА обійти через skills

### 1.2 Tool Definitions
- Вбудовані tools (Read, Write, Edit, Bash, Grep, Glob, etc.)
- Як tools описуються в system prompt
- Пріоритети tools (dedicated > bash)

### 1.3 Behavioral Defaults
- Стиль комунікації
- Підхід до завдань
- Безпека та етика

## 2. Що потрібно навчити через Skills

### 2.1 Domain Knowledge
- Маркетинг, бізнес, технічні домени
- Workflow patterns
- Output formats

### 2.2 Tool Usage Patterns
- MCP server usage
- Multi-tool orchestration
- Error handling

### 2.3 Quality Standards
- Evaluation criteria
- Self-check rubrics
- Handoff protocols

## 3. System Prompt Patterns for Skills

### 3.1 Effective Patterns
- [pattern]: [де використовується, чому працює]

### 3.2 Anti-patterns
- [pattern]: [чому погано, як виправити]

## 4. Validation vs Existing Report

### 4.1 Confirmed Findings
- [finding]: [наш аналіз підтверджує]

### 4.2 Corrected Findings
- [finding]: [наш аналіз спростовує/уточнює, причина]

### 4.3 New Findings
- [finding]: [чого не було в старому звіті]

## 5. Висновки для Skill Factory
```

**Step 2: Analyze system prompt files**

Read all files in both system prompt directories. Map what Claude "knows" vs "needs to learn".

**Step 3: Compare with existing report**

Read `../Analysis_reports_md/system_prompts_analysis.md`. Section 4 — what's confirmed, corrected, new.

**Step 4: Quality gate**

- [ ] Sections 1-3 complete
- [ ] Section 4 has validation against existing report
- [ ] ≥5 effective patterns, ≥3 anti-patterns identified
- [ ] Clear separation: "knows" vs "needs teaching"

**Step 5: Commit**

```bash
git add foundation/analysis/system_prompt_analysis.md
git commit -m "docs(phase0): A2 — system prompt analysis"
```

---

### Task A3: Skills/MCP/Agents Ecosystem Analysis (~1 session)

**Depends on:** A1, A2 (need platform + prompt understanding).

**Files:**
- Read: `../docs/context_doc/claude_skills/` (68 skills, plugins, connectors)
- Read: `../docs/context_doc/antropic_docs/skills-main 2/`
- Read: `.claude/skills/_index.md` (our skill catalog)
- Read: `foundation/analysis/anthropic_platform_analysis.md` (A1)
- Read: `foundation/analysis/system_prompt_analysis.md` (A2)
- Compare: `../Analysis_reports_md/anthropic_skills_analysis.md`
- Compare: `../Analysis_reports_md/anthropic_commands_analysis.md`
- Compare: `../Analysis_reports_md/anthropic_connectors_analysis.md`
- Compare: `../Analysis_reports_md/claude_technical_plugins_analysis.md`
- Create: `foundation/analysis/skills_ecosystem_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз екосистеми Skills / MCP / Agents

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Залежності:** A1, A2

---

## 1. Format Patterns

### 1.1 Skill Format Standard
- SKILL.md structure (size, sections, order)
- References pattern
- Progressive disclosure

### 1.2 Agent Format
- Identity blocks
- Boundary definitions
- Handoff contracts

### 1.3 Command Format
- Routing schema
- Input/output contracts

### 1.4 MCP Server Integration
- Server declaration (.mcp.json)
- Tool definitions
- Auto-accept patterns

## 2. Orchestration Patterns

### 2.1 Single Skill Execution
### 2.2 Multi-Skill Pipelines
### 2.3 Agent Delegation (subagents)
### 2.4 Human-in-the-Loop

## 3. Safety Patterns

### 3.1 Permission System
### 3.2 Deny Rules
### 3.3 Hook Guards
### 3.4 Sandbox Isolation

## 4. Programming Plugin Opportunities

### 4.1 Existing Plugins Catalog
| Plugin | Category | Can adopt? | Effort |
|--------|----------|-----------|--------|

### 4.2 Dev Skills for Adoption
- [skill]: [що робить, чому корисний для нашого tech dept]

## 5. Validation vs Existing Reports (4 reports)

### 5.1 skills_analysis.md — confirmed / corrected / new
### 5.2 commands_analysis.md — confirmed / corrected / new
### 5.3 connectors_analysis.md — confirmed / corrected / new
### 5.4 technical_plugins_analysis.md — confirmed / corrected / new

## 6. Висновки для Skill Factory
```

**Step 2-5: Analyze each area** (format, orchestration, safety, plugins)

**Step 6: Validate against 4 existing reports**

**Step 7: Quality gate**

- [ ] All 6 sections complete
- [ ] ≥10 format patterns extracted
- [ ] ≥5 orchestration patterns
- [ ] ≥3 safety patterns
- [ ] Plugin table with ≥10 entries
- [ ] ≥3 dev skills identified for adoption
- [ ] Validation against all 4 existing reports

**Step 8: Commit**

```bash
git add foundation/analysis/skills_ecosystem_analysis.md
git commit -m "docs(phase0): A3 — skills/MCP/agents ecosystem analysis"
```

---

### Task A4: Competitive Prompts Analysis (~0.5 session)

**Depends on:** A1-A3 (need our ecosystem understanding to compare).

**Files:**
- Read: `../docs/context_doc/` — any leaked prompts / competitor analysis docs
- Read: `foundation/analysis/` — A1-A3 outputs
- Compare: `../Analysis_reports_md/agent_prompts_analysis.md`
- Create: `foundation/analysis/competitive_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз конкурентних промптів

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Залежності:** A1, A2, A3

---

## 1. Competitor Matrix

| Agent | Source | Key Patterns | Strengths | Weaknesses |
|-------|--------|-------------|-----------|------------|
| Manus | | | | |
| Cursor | | | | |
| Bolt | | | | |
| Lovable | | | | |
| Replit | | | | |

## 2. Patterns to Adopt
### 2.1 [Pattern name]
- **Де бачили:** [competitor]
- **Суть:** [опис]
- **Як адаптувати:** [для NanoClaw]

## 3. Anti-patterns to Avoid
## 4. Unique Advantages (ми маємо, конкуренти ні)
## 5. Validation vs Existing Report
## 6. Висновки для Skill Factory
```

**Step 2-4: Analyze competitors, extract patterns**

**Step 5: Quality gate**

- [ ] ≥5 competitors analyzed
- [ ] ≥5 patterns to adopt
- [ ] ≥3 anti-patterns documented
- [ ] Validation against existing report
- [ ] Unique advantages identified

**Step 6: Commit**

```bash
git add foundation/analysis/competitive_analysis.md
git commit -m "docs(phase0): A4 — competitive prompts analysis"
```

---

### Task A5: Validation + Cross-Synthesis (~1 session)

**Depends on:** A1-A4 (all analysis must be complete). **KEY ARTIFACT.**

**Files:**
- Read: `foundation/analysis/anthropic_platform_analysis.md` (A1)
- Read: `foundation/analysis/system_prompt_analysis.md` (A2)
- Read: `foundation/analysis/skills_ecosystem_analysis.md` (A3)
- Read: `foundation/analysis/competitive_analysis.md` (A4)
- Read: ALL 7 files in `../Analysis_reports_md/`
- Compare: `../Analysis_reports_md/meta_engineering_principles.md` (previous synthesis)
- Create: `foundation/analysis/meta_synthesis_v2.md`

**Step 1: Define synthesis template**

```markdown
# Meta-Синтез v2 — Авторитетний зведений аналіз

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Замінює:** Analysis_reports_md/meta_engineering_principles.md
**Залежності:** A1, A2, A3, A4 + 7 існуючих звітів

---

## 1. Cross-Validation Matrix

| Знахідка | A1 | A2 | A3 | A4 | Old Reports | Вердикт |
|----------|----|----|----|----|-------------|---------|
| [finding] | ✓/✗/— | ... | ... | ... | ... | CONFIRMED/CORRECTED/NEW |

## 2. Підтверджені паттерни (≥2 джерела)
## 3. Спростовані/уточнені знахідки
## 4. Нові знахідки (відсутні в старих звітах)

## 5. Consolidated Patterns (≥30)

### 5.1 Architecture Patterns
### 5.2 Safety Patterns
### 5.3 Quality Patterns
### 5.4 Orchestration Patterns
### 5.5 Domain Patterns

## 6. Gap Analysis

### 6.1 Knowledge Gaps
### 6.2 Capability Gaps
### 6.3 Tool Gaps

## 7. Recommendations for Standards

### 7.1 MUST (обов'язкові для всіх артефактів)
### 7.2 SHOULD (рекомендовані)
### 7.3 MAY (опціональні)
### 7.4 MUST NOT (заборонені)

## 8. Quality of Previous Reports

| Report | Grade | Key Issue | Action |
|--------|-------|-----------|--------|
```

**Step 2-5: Cross-validate all sources**

**Step 6: Quality gate — THIS IS THE CRITICAL GATE**

- [ ] Cross-validation matrix has ≥20 findings checked across ≥3 sources each
- [ ] ≥30 consolidated patterns identified
- [ ] Gap analysis with ≥5 gaps per category
- [ ] MUST/SHOULD/MAY/MUST NOT — ≥5 items each
- [ ] All 7 existing reports graded
- [ ] Document supersedes meta_engineering_principles.md

**Step 7: Commit**

```bash
git add foundation/analysis/meta_synthesis_v2.md
git commit -m "docs(phase0): A5 — meta synthesis v2 (authoritative cross-validation)"
```

---

### Task A6: Business Requirements Synthesis (~0.5 session)

**Depends on:** A5 (need synthesis to map to business needs).

**Files:**
- Read: `foundation/analysis/meta_synthesis_v2.md` (A5)
- Read: `../docs/context_doc/My_skill_and_insite/` (YAKOMANДА, Chain v3)
- Read: `docs/phase-0-tasks/PROJECT_MASTER.md` (architecture)
- Create: `foundation/analysis/business_requirements_synthesis.md`

**Step 1: Define synthesis template**

```markdown
# Синтез бізнес-вимог

**Дата:** YYYY-MM-DD
**Статус:** DRAFT
**Залежності:** A5 + YAKOMANДА + Chain v3 + PROJECT_MASTER

---

## 1. YAKOMANДА — Building Blocks для ВСІХ артефактів

### 1.1 52 блоки → категоризація
| Block ID | Name | Artifact Types | When to Use |
|----------|------|---------------|-------------|

### 1.2 Evidence Grading → стандарт для ВСІХ handoffs
### 1.3 Decision Matrix → вибір блоків за типом задачі

## 2. Marketing Chain v3 — 14 ланок

### 2.1 Mapping: chain link → artifact type → YAKOMANДА blocks
| Chain Link | Artifact | Type | Blocks | Priority |
|-----------|----------|------|--------|----------|

## 3. NanoClaw Architecture Requirements

### 3.1 Container constraints → skill format
### 3.2 Channel constraints → output format
### 3.3 IPC constraints → handoff format

## 4. Factory Requirements (shapes M1+M2)

### 4.1 Universal artifact types (5)
### 4.2 Per-artifact requirements matrix
### 4.3 Quality gates per artifact type
### 4.4 YAKOMANДА integration points

## 5. Department Artifact Estimates

### 5.1 Marketing (~73 files breakdown)
### 5.2 Technical (~30 files breakdown)
### 5.3 Meta/Communication (~15 files)
### 5.4 Platform (~20 files)

## 6. Priority Matrix

| Artifact | Business Value | Complexity | Priority |
|----------|---------------|-----------|----------|
```

**Step 2-5: Map YAKOMANДА to factory, chain to artifacts, estimate departments**

**Step 6: Quality gate**

- [ ] All 52 YAKOMANДА blocks categorized
- [ ] All 14 chain links mapped to artifacts
- [ ] Factory requirements clear for ALL 5 artifact types
- [ ] Department breakdowns add up to ~138 total
- [ ] Priority matrix with ≥20 entries

**Step 7: Commit**

```bash
git add foundation/analysis/business_requirements_synthesis.md
git commit -m "docs(phase0): A6 — business requirements synthesis (YAKOMANДА → factory)"
```

---

## TRACK B — Platform Analysis (parallel session)

> Can run independently in a SEPARATE chat session (or as subagents).
> NO dependencies on Track A. Total: ~3 sessions.

---

### Task B1: TypeScript Platform Analysis (~1 session)

**Files:**
- Read: `../docs/context_doc/typescript_docs/` (all files)
- Read: `src/` (NanoClaw source, read-only)
- Create: `foundation/analysis/typescript_platform_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз платформи TypeScript

**Дата:** YYYY-MM-DD
**Статус:** DRAFT

---

## 1. NanoClaw Source Architecture

### 1.1 Directory Map
| Directory | Purpose | Key Files | Extension Points |
|-----------|---------|-----------|-----------------|

### 1.2 Entry Points
- Main: src/index.ts → ...
- Channels: src/channels/ → ...
- Containers: src/containers/ → ...

### 1.3 Skill Loading Mechanism
- How skills are discovered
- How skills are executed
- Skill lifecycle

## 2. TypeScript Constraints for Skills

### 2.1 Type System Patterns
- Required types/interfaces
- Generics usage
- Strict mode implications

### 2.2 Module System
- ESM vs CJS
- Import patterns
- Re-export conventions

### 2.3 Build & Runtime
- tsconfig requirements
- Runtime (Node.js version)
- Dependencies management

## 3. Extension Points (without modifying src/)

### 3.1 Skills (.claude/skills/)
### 3.2 Commands (.claude/commands/)
### 3.3 Hooks (.claude/hooks/)
### 3.4 Groups (groups/{dept}/)
### 3.5 MCP Servers (.mcp.json)

## 4. NanoClaw API Surface

### 4.1 Public APIs (safe to use)
### 4.2 Internal APIs (don't touch)
### 4.3 Configuration Points

## 5. Висновки для Skill Factory
```

**Step 2-5: Analyze TS docs + NanoClaw source**

**Step 6: Quality gate**

- [ ] NanoClaw directory map complete
- [ ] ≥5 extension points documented
- [ ] TS constraints clear for skill authors
- [ ] API surface mapped (public vs internal)

**Step 7: Commit**

```bash
git add foundation/analysis/typescript_platform_analysis.md
git commit -m "docs(phase0): B1 — TypeScript platform analysis"
```

---

### Task B2: Telegram Platform Analysis (~1 session)

**Files:**
- Read: `../docs/context_doc/telegram_api/` (Bot API 9.3)
- Read: `../docs/context_doc/telegram_mtproto/` (GramJS)
- Read: `../docs/context_doc/Telegram_all/` (additional TG docs)
- Create: `foundation/analysis/telegram_platform_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз платформи Telegram

**Дата:** YYYY-MM-DD
**Статус:** DRAFT

---

## 1. Bot API 9.3 — Full Method Map

### 1.1 Messaging
| Method | Purpose | NanoClaw Use | Skill Needed? |
|--------|---------|-------------|---------------|

### 1.2 Inline Keyboards & Callbacks
### 1.3 Forums (Topics)
### 1.4 Payments
### 1.5 Streaming / Long-running
### 1.6 Mini Apps (WebApps)
### 1.7 Media & Files
### 1.8 Admin & Moderation

## 2. MTProto / GramJS Capabilities

### 2.1 Userbot Features (Phase 2.5)
### 2.2 Monitoring & Intelligence
### 2.3 Limitations vs Bot API

## 3. NanoClaw ↔ Telegram Integration

### 3.1 Current: src/channels/telegram.ts
### 3.2 Message Flow: TG → NanoClaw → TG
### 3.3 Gaps: API methods not yet supported

## 4. API → Skills Mapping

| API Method Group | Possible Skill | Priority | Complexity |
|-----------------|---------------|----------|-----------|

## 5. Висновки для Skill Factory
```

**Step 2-5: Full Bot API mapping + MTProto analysis**

**Step 6: Quality gate**

- [ ] ≥50 API methods mapped
- [ ] Gaps table (what NanoClaw doesn't support yet)
- [ ] Skills mapping with priorities
- [ ] MTProto section (even if Phase 2.5)

**Step 7: Commit**

```bash
git add foundation/analysis/telegram_platform_analysis.md
git commit -m "docs(phase0): B2 — Telegram platform analysis"
```

---

### Task B3: External Ecosystem Analysis (~1 session)

**Files:**
- Read: `../docs/context_doc/marketing_skills_repo/`
- Read: `.claude/skills/_index.md` (our catalog, 48+ plugins)
- Web search: community MCP servers, skill repos
- Create: `foundation/analysis/external_ecosystem_analysis.md`

**Step 1: Define analysis template**

```markdown
# Аналіз зовнішньої екосистеми

**Дата:** YYYY-MM-DD
**Статус:** DRAFT

---

## 1. Marketing Skills Repos

| Repo/Source | Skills Count | Quality | Relevance | Action |
|------------|-------------|---------|-----------|--------|

## 2. Community MCP Servers

| Server | Purpose | Maturity | Integration Effort |
|--------|---------|----------|--------------------|

## 3. Classification Table

| Asset | Category | Action | Effort | Priority |
|-------|----------|--------|--------|----------|
| [name] | skill/MCP/template | use-as-is / adapt / write-new | S/M/L | P1-P3 |

## 4. External Dependencies Risk

### 4.1 License Compatibility
### 4.2 Maintenance Status
### 4.3 API Stability

## 5. Висновки для Skill Factory
```

**Step 2-4: Catalog external resources**

**Step 5: Quality gate**

- [ ] ≥20 external assets classified
- [ ] Clear action per asset (use/adapt/write)
- [ ] Risk assessment for dependencies
- [ ] ≥5 "use-as-is" candidates identified

**Step 6: Commit**

```bash
git add foundation/analysis/external_ecosystem_analysis.md
git commit -m "docs(phase0): B3 — external ecosystem analysis"
```

---

## Merge Readiness Checklist

Before proceeding to Merge Point 1 (Standardization + Factory), verify:

### Track A Outputs (6 files)
- [ ] `foundation/analysis/anthropic_platform_analysis.md` — A1
- [ ] `foundation/analysis/system_prompt_analysis.md` — A2
- [ ] `foundation/analysis/skills_ecosystem_analysis.md` — A3
- [ ] `foundation/analysis/competitive_analysis.md` — A4
- [ ] `foundation/analysis/meta_synthesis_v2.md` — A5 (KEY)
- [ ] `foundation/analysis/business_requirements_synthesis.md` — A6

### Track B Outputs (3 files)
- [ ] `foundation/analysis/typescript_platform_analysis.md` — B1
- [ ] `foundation/analysis/telegram_platform_analysis.md` — B2
- [ ] `foundation/analysis/external_ecosystem_analysis.md` — B3

### Cross-check
- [ ] All 9 files exist and have no TODOs/placeholders
- [ ] A5 meta_synthesis_v2.md references findings from A1-A4
- [ ] A6 has concrete numbers for artifact estimates
- [ ] B1 NanoClaw extension points align with A1 platform constraints
- [ ] B2 Telegram skills map aligns with A6 department estimates

### Final commit
```bash
git add foundation/analysis/
git commit -m "docs(phase0): Track A+B complete — ready for Merge Point 1"
```

---

## Execution Notes

### Session mapping (recommended)
| Session | Tasks | Est. time |
|---------|-------|-----------|
| Session 1 | Prerequisites + A1 | ~2h |
| Session 2 | A2 + A3 | ~2h |
| Session 3 | A4 + A5 | ~2h |
| Session 4 | A6 + merge readiness | ~1h |
| Parallel 1 | B1 + B2 | ~2h (runs with Session 1-2) |
| Parallel 2 | B3 | ~1h (runs with Session 3) |

### Risk mitigations
- If context_doc data is missing → STOP at Prerequisites, notify user
- If existing reports contradict new analysis → document in validation sections, don't discard
- If NanoClaw source unclear → flag in B1, proceed with best understanding
- If session runs out mid-task → commit WIP, note in pipeline-state.md
