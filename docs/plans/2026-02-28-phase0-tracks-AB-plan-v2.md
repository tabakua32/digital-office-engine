# Phase 0: Implementation Plan v2 — STEAL → ADAPT → IMPROVE

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract maximum value from context_doc library (37,956 files, 1GB) to build NanoClaw OS artifacts — skills, agents, templates, commands, context files.

**Philosophy:** context_doc is a library of READY SOLUTIONS, not academic reading material. Goal = find what to steal, adapt, or improve. NOT write reports about what we read.

**Design Doc:** `docs/plans/2026-02-28-full-roadmap-design.md` — source of truth for scope.

**Replaces:** `docs/plans/2026-02-28-phase0-tracks-AB-plan.md` (v1, academic approach)

---

## Core Protocol: CALIBRATE → INVENTORY → EVALUATE → HARVEST

### Before EVERY directory analysis:

```
┌─────────────────────────────────────┐
│  CALIBRATE (user answers 3-7 Qs)   │
│  ↓                                  │
│  INVENTORY (ls + README scan)       │
│  ↓                                  │
│  EVALUATE (COPY/ADAPT/INSPIRE/SKIP) │
│  ↓                                  │
│  HARVEST (deep read COPY+ADAPT)     │
│  ↓                                  │
│  OUTPUT (collected assets + notes)  │
└─────────────────────────────────────┘
```

**CALIBRATE = mandatory.** Claude asks 3-7 questions before touching any directory:
- What did you collect here and WHY?
- What specifically do you want to GET from this?
- What's GOLD vs noise in your opinion?
- Any specific repos/files you know are valuable?
- What's the end goal for artifacts from this source?

User answers → Claude knows exactly what to look for → no wasted reads.

### Verdict system for evaluation:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **COPY** | Ready solution, works | Copy as-is, adapt names/paths |
| **ADAPT** | Good idea, needs rework | Take structure/logic, write our version |
| **INSPIRE** | Interesting approach | Note in patterns, don't copy |
| **SKIP** | Not relevant or low quality | Ignore |

### Context window budget:
- CALIBRATE: ~0 tokens (user answers)
- INVENTORY: ~5K tokens (ls + README headers)
- EVALUATE: ~10-20K tokens (scan key files)
- HARVEST: ~50-100K tokens (deep read COPY+ADAPT files)
- OUTPUT: ~20K tokens (write results)
- **Total per task: stays under 200K**

---

## Phase 0.1 — INVENTORY + CALIBRATE (1-2 sessions)

### Task INV-1: Full Inventory Scan

**Step 1: Scan all directories**

```bash
# For each dir in context_doc:
ls ../docs/context_doc/{dir}/ | head -20
# + count files, check size
```

**Step 2: Create inventory file**

Create `foundation/inventory.md`:

```markdown
# Context Library Inventory

| Directory | Files | Size | Content Type | User's Goal |
|-----------|-------|------|-------------|-------------|
| Telegram_all | 5385 | 146MB | TG bot repos | Ready Claude↔TG integrations |
| marketing_skills_repo | 28671 | 604MB | Marketing skill repos | COPY/ADAPT skills |
| claude_skills | 2320 | 19MB | Official+community skills | Format standard + tech skills |
| antropic_docs | 1177 | 220MB | SDK, API, cookbooks | Platform constraints |
| My_skill_and_insite | 162 | 2.7MB | YAKOMANДА, Chain v3 | Building blocks for ALL |
| nanoclaw_main_REPO_test | 235 | 10MB | NanoClaw fork | Runtime understanding |
| nanoclaw_reserch_arhitecture | 5 | 164KB | Architecture notes | Phase design |
| Analysis_reports_md (separate) | 7 | ~200KB | Previous analysis | Validation |
```

For EACH directory:
1. List top-level subdirectories/repos
2. Note what each contains (1 line)
3. Flag obvious GOLD candidates

**Step 3: Commit**

```bash
git add foundation/inventory.md
git commit -m "docs(phase0): INV-1 — full context library inventory"
```

---

## Phase 0.2 — EVALUATE per directory (3-5 sessions)

Each task below follows the protocol: CALIBRATE → scan → evaluate → harvest.

**IMPORTANT:** Each task starts with CALIBRATE questions to the user. DO NOT skip this step. Ask questions, wait for answers, THEN proceed.

---

### Task EVAL-TG: Telegram Integrations (Telegram_all/)

**CALIBRATE — ask user:**
1. Which repos here are actual Claude↔TG bots vs just TG libraries?
2. What architecture do you want — direct bot, webhook, or NanoClaw channel?
3. Any repo here you already tested and liked?
4. Do you need group/forum support or just DM?
5. What TG features matter most — keyboards, payments, streaming, forums?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Inventory | `ls` each repo, read README | ~10 files |
| Evaluate | Check main bot file per repo: architecture, quality, Claude integration | ~20 files |
| Harvest | COPY+ADAPT repos: full code read, extract patterns | ~30 files |
| Output | `foundation/harvest/telegram_integrations.md` — ready code + patterns | — |

**Output structure:**
```markdown
# Telegram Integrations Harvest

## COPY (ready to use)
### [repo-name]
- Architecture: [how it connects Claude to TG]
- Key files: [list]
- What to copy: [specific code/patterns]
- Adaptation needed: [minimal changes]

## ADAPT (good idea, needs rework)
### [repo-name]
- What's good: [pattern/approach]
- What to change: [for NanoClaw compatibility]

## Patterns Collected
- [pattern]: [where found, how to apply]

## Decision: recommended architecture for NanoClaw TG channel
```

**Commit:**
```bash
git add foundation/harvest/telegram_integrations.md
git commit -m "docs(phase0): EVAL-TG — Telegram integrations evaluated"
```

---

### Task EVAL-MKT: Marketing Skills (marketing_skills_repo/)

**CALIBRATE — ask user:**
1. These repos — are they Claude Code skills or general marketing tools?
2. Which marketing categories matter most — content, SEO, analytics, social, all?
3. Any repos here you already reviewed and rated?
4. Do you want skills that work standalone or integrated into chains?
5. Quality bar — what makes a skill "good enough to copy"?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Inventory | `ls` top repos, read README per repo | ~30 files |
| Evaluate | Read SKILL.md per repo, classify COPY/ADAPT/SKIP | ~40 files |
| Harvest | COPY skills: full read. ADAPT: structure only | ~40 files |
| Output | `foundation/harvest/marketing_skills.md` | — |

**Output structure:**
```markdown
# Marketing Skills Harvest

## COPY (ready to use, ≥70 quality)
| Skill | Source Repo | Category | What to Copy | Adaptation |
|-------|------------|----------|-------------|-----------|

## ADAPT (good structure, needs content rework)
| Skill | Source Repo | What's Good | What to Change |
|-------|------------|------------|---------------|

## Patterns
- Best format examples (link to specific files)
- Common sections across quality skills
- Quality markers (what makes good skills good)

## Coverage Map
| Chain Link (14) | COPY skills | ADAPT skills | WRITE from scratch |
|----------------|------------|-------------|-------------------|
```

**Commit:**
```bash
git add foundation/harvest/marketing_skills.md
git commit -m "docs(phase0): EVAL-MKT — marketing skills evaluated"
```

---

### Task EVAL-SKILLS: Claude Skills Ecosystem (claude_skills/)

**CALIBRATE — ask user:**
1. What do you want from official skills — format standard or actual skills to copy?
2. Are you more interested in skill structure or skill content?
3. Which categories: engineering, design, data, customer-support, all?
4. Do you want to find tech dept skills here?
5. Any specific skills you already use and like?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Inventory | `ls` categories, count per category | ~10 files |
| Evaluate | Best skill per category: read SKILL.md, rate format | ~25 files |
| Harvest | Extract format standard + COPY tech skills | ~20 files |
| Output | `foundation/harvest/claude_skills_format.md` | — |

**Output includes:**
- Canonical skill format (extracted from best examples)
- Tech skills for dev department (COPY list)
- Agent format patterns
- Command format patterns

**Commit:**
```bash
git add foundation/harvest/claude_skills_format.md
git commit -m "docs(phase0): EVAL-SKILLS — Claude skills format + tech skills"
```

---

### Task EVAL-SDK: Anthropic Platform (antropic_docs/)

**CALIBRATE — ask user:**
1. SDK docs — do you need constraints/limits or implementation patterns?
2. Cookbooks — looking for specific patterns or general best practices?
3. System prompts — need to understand defaults or override patterns?
4. What's priority: Agent SDK, API limits, or tool patterns?
5. Any specific API features you plan to use heavily (batch, caching, thinking)?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Inventory | `ls` each subdirectory | ~5 files |
| Evaluate | SDK: constraints docs. API: limits/pricing. Cookbooks: pattern files | ~20 files |
| Harvest | Extract rules matrix + patterns | ~25 files |
| Output | `foundation/harvest/anthropic_platform_rules.md` | — |

**Output includes:**
- Model matrix (context, output, cost, best-for)
- API constraints (rate limits, batch rules, caching TTL)
- SDK extension points (hooks, skills, commands, agents)
- NanoClaw runtime compatibility rules
- Patterns from cookbooks (with source links)

**Commit:**
```bash
git add foundation/harvest/anthropic_platform_rules.md
git commit -m "docs(phase0): EVAL-SDK — Anthropic platform rules extracted"
```

---

### Task EVAL-MCP: MCP Servers Assessment

**CALIBRATE — ask user:**
1. Which MCP servers are you considering connecting?
2. Priority — search, database, file storage, APIs, other?
3. Are there MCP servers in context_doc or do I search web?
4. Quality bar — production-ready or experimental OK?
5. Any MCP servers you already tested?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Inventory | Check what's in context_doc + search community | ~10 files |
| Evaluate | Per server: maturity, relevance, integration effort | ~15 files |
| Output | `foundation/harvest/mcp_servers_assessment.md` | — |

**Output:**
- Ready to connect (plug-and-play)
- Needs configuration
- Skip (immature or irrelevant)

**Commit:**
```bash
git add foundation/harvest/mcp_servers_assessment.md
git commit -m "docs(phase0): EVAL-MCP — MCP servers assessed"
```

---

### Task EVAL-YAKO: YAKOMANДА + Business (My_skill_and_insite/)

**CALIBRATE — ask user:**
1. Which YAKOMANДА blocks are most proven/tested?
2. Chain v3 — all 14 links active or some theoretical?
3. Evidence Grading — how strict for Phase 0?
4. Decision Matrix — already working or needs building?
5. Any blocks that should apply to ALL artifacts vs marketing-only?

**After calibration:**

| Step | Action | Budget |
|------|--------|--------|
| Deep read | ALL files (162 = small, this is GOLD) | ~162 files |
| Output | `foundation/harvest/yakomanda_building_blocks.md` | — |

**Output:**
- 52 blocks categorized by artifact type
- Evidence Grading standard
- Decision Matrix
- Chain v3 mapping to artifact pipeline

**Commit:**
```bash
git add foundation/harvest/yakomanda_building_blocks.md
git commit -m "docs(phase0): EVAL-YAKO — YAKOMANДА building blocks mapped"
```

---

### Task EVAL-REPORTS: Validate Previous Analysis (Analysis_reports_md/)

**No calibration needed** — 7 small files, just read and validate.

| Step | Action | Budget |
|------|--------|--------|
| Deep read | All 7 reports | ~7 files |
| Output | `foundation/harvest/reports_validation.md` | — |

**Output:** Per report: confirmed / corrected / new findings.

**Commit:**
```bash
git add foundation/harvest/reports_validation.md
git commit -m "docs(phase0): EVAL-REPORTS — previous analysis validated"
```

---

## Phase 0.3 — SYNTHESIZE (2-3 sessions)

**Prerequisite:** All EVAL tasks complete. All harvest files in `foundation/harvest/`.

### Task SYN-1: Cross-Synthesis + Standard

**Input:** All 7 harvest files + 7 validated reports
**Output:**
- `foundation/meta_synthesis_v2.md` — authoritative patterns + rules
- `foundation/skill_standard.md` — format for all 5 artifact types
- `foundation/skill_taxonomy.md` — MECE matrix with COPY/ADAPT/WRITE per cell

### Task SYN-2: Build Factory

**Input:** SYN-1 outputs + harvest files (especially format examples)
**Output:** `nanoclaw-skill-factory/` with SKILL.md, references, scripts, templates

### Task SYN-3: Validate Factory

**Input:** Factory + 3-5 test artifacts (mix of COPY and new)
**Output:** Validated factory, audit passes

---

## Phase 0.4 — PRODUCTION (Track C + D from design doc)

Uses factory to produce all ~138 artifacts. Separate plan after factory is validated.

---

## Commands — Full List

### Phase 0.1 — Inventory
```
Phase 0 INV-1: Full inventory scan of context_doc. cd digital-office-engine && cat foundation/pipeline-state.md
```

### Phase 0.2 — Evaluate (each starts with CALIBRATE questions)
```
Phase 0 EVAL-TG: Evaluate Telegram integrations. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-MKT: Evaluate marketing skills. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-SKILLS: Evaluate Claude skills ecosystem. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-SDK: Evaluate Anthropic platform. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-MCP: Assess MCP servers. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-YAKO: Map YAKOMANДА building blocks. CALIBRATE first. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 EVAL-REPORTS: Validate previous analysis. cd digital-office-engine && cat foundation/pipeline-state.md
```

### Phase 0.3 — Synthesize
```
Phase 0 SYN-1: Cross-synthesis + standard + taxonomy. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 SYN-2: Build universal factory. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 SYN-3: Validate factory with test artifacts. cd digital-office-engine && cat foundation/pipeline-state.md
```

### Phase 0.4 — Production (after factory)
```
Phase 0 PROD-TG: Generate Telegram skills via factory. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 PROD-MKT: Generate marketing artifacts via factory. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 PROD-TECH: Generate technical artifacts via factory. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 PROD-META: Generate meta/communication artifacts. cd digital-office-engine && cat foundation/pipeline-state.md
```

### Final Integration
```
Phase 0 FINAL-1: NanoClaw architecture integration. cd digital-office-engine && cat foundation/pipeline-state.md
```
```
Phase 0 FINAL-2: E2E testing + bug fixing. cd digital-office-engine && cat foundation/pipeline-state.md
```

---

## Parallelism Map

```
INV-1 (sequential — need full picture first)
  ↓
EVAL-TG ─────┐
EVAL-MKT ────┤ (can run 2-3 in parallel)
EVAL-SKILLS ─┤
EVAL-SDK ────┤
EVAL-MCP ────┤
EVAL-YAKO ───┤
EVAL-REPORTS ┘
  ↓
SYN-1 → SYN-2 → SYN-3 (sequential)
  ↓
PROD-TG ──────┐
PROD-MKT ─────┤ (parallel)
PROD-TECH ────┤
PROD-META ────┘
  ↓
FINAL-1 → FINAL-2 (sequential)
```

## Session Estimates

| Phase | Tasks | Sequential | With parallel |
|-------|-------|-----------|--------------|
| 0.1 Inventory | 1 | 1 | 1 |
| 0.2 Evaluate | 7 | 7 | 3-4 |
| 0.3 Synthesize | 3 | 3 | 3 |
| 0.4 Production | 4 | 4 | 2 |
| Final | 2 | 2 | 2 |
| **TOTAL** | **17** | **17** | **~11-12** |
