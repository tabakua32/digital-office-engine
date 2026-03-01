# TZ-0.1: Skill Standard + Taxonomy

> **Phase**: 0 — Foundation Layer
> **Priority**: P0 (root — ALL other TZs depend on this)
> **Sessions**: 2-3
> **Dependencies**: — (none, this is the root)
> **Verdict**: BUILD 60% | ADAPT 30% | COPY 10%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.2, §0.3

---

## 1. Мета

Визначити єдиний формат для ВСІХ skills у NanoClaw OS та класифікацію
(taxonomy), щоб 30+ скілів у системі були керованими, сумісними між
рантаймами, та мали передбачувану якість.

**Без цього ТЗ**: кожен скіл — інший формат, іменування, якість. Pipeline
маршрутизації не працює. Evaluation неможлива. Агент-виконавець не знає
як будувати скіли.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Skill File Structure

```
[skill-name]/
├── SKILL.md              ← Головний файл (<500 рядків)
│                            Sandwich: top 5% + bottom 10% = critical
├── references/           ← Progressive disclosure (read on demand)
│   └── [topic].md
├── scripts/              ← Automation (optional)
│   └── audit_skill.py
├── assets/               ← Static resources
│   ├── templates/
│   └── examples/
└── CLAUDE.md             ← NanoClaw-only: persistent memory template
```

#### B. SKILL.md Sandwich Structure

| Section | % | Content |
|---------|---|---------|
| **HEADER** | 5% | YAML frontmatter + meta fields |
| **QUICK REF** | 15% | Routing table, I/O contract, anti-patterns |
| **CORE LOGIC** | 60% | Identity, process steps, quality gates, error handling |
| **OUTPUT** | 10% | Format per runtime, channel hints, self-check rubric |
| **CRITICAL RULES** | 10% | Repeated warnings, anti-sycophancy, safety |

#### C. YAML Frontmatter (mandatory)

```yaml
---
name: skill-name
version: "1.0.0"
author: nanoclaw
type: skill          # agent | skill | connector | command | module | process
domain: marketing/content  # marketing/{sub} | dev-ops | visual | data | communication | meta
task_type: generative      # analytical | generative | transformational | orchestration
compatibility:
  - nanoclaw
  - claude-code
  - claude-ai
  - cowork
model_tier: sonnet         # opus | sonnet | haiku
effort_level: high         # max | high | medium | low | disabled
context_deps:              # required context modules from Layer 2
  - product/spec
  - audience/icp
  - brand/voice
thread_scope: topic        # public | topic | private | any
triggers:                  # routing trigger phrases
  - "write article"
  - "create content"
  - "blog post"
---
```

#### D. Taxonomy Matrix (6 Domains × 6 Functions)

**Domains** (MECE по предметній області):

| Domain | Scope | Marketing Chain |
|--------|-------|-----------------|
| `marketing/` | Full Marketing Chain v3 | ①-⑫ (15 sub-domains) |
| `dev-ops/` | Debug, test, security, deploy, monitor | cross |
| `visual/` | Design, image, video, infographic | ④.5 ⑤ ⑥ |
| `data/` | Analytics, reporting, ETL | ⑩ ⑫ |
| `communication/` | Email, social, messenger, voice, PR | ⑥ ⑦ ⑧ |
| `meta/` | Factory, audit, orchestration, routing | cross |

**Marketing sub-domains** (повний Marketing Chain v3):

```
marketing/
├── market-intelligence/   (①)
├── customer-analysis/     (②)
├── pmf-validation/        (⓪)
├── positioning/           (③)
├── offer/                 (④)
├── brand/                 (④.5)
├── content/               (⑤)
├── geo-aeo/               (⑤.5)
├── distribution/          (⑥)
├── conversion/            (⑦)
├── customer-experience/   (⑧)
├── retention/             (⑨)
├── analytics/             (⑩)
├── scaling/               (⑪)
└── feedback/              (⑫)
```

**Functions** (MECE по типу дії):

| Function | Autonomy | What it does | Model | Effort |
|----------|----------|-------------|-------|--------|
| `agent` | HIGH | Plans, delegates, decides | Opus/Sonnet | max/high |
| `skill` | MED | Executes task on demand | Sonnet/Haiku | high/medium |
| `connector` | LOW | MCP bridge to external API | N/A (config) | N/A |
| `command` | LOW | Slash-command, atomic | Haiku | disabled |
| `module` | NONE | Context block (data only) | N/A (file) | N/A |
| `process` | ORCH | Multi-step workflow, orchestrates others | Sonnet | high |

**Task Types** (for output format routing):

| Task Type | Examples | Default Model |
|-----------|----------|---------------|
| `analytical` | Research, audit, analysis | Sonnet |
| `generative` | Copy, content, email | Sonnet |
| `transformational` | Reformat, adapt, convert | Haiku |
| `orchestration` | Delegation, routing, aggregation | Sonnet |

#### E. Naming Conventions

```
Skill folder:   {domain}-{name}
                 marketing-content-copywriter
                 meta-skill-factory
                 dev-ops-code-reviewer

SKILL.md name:   Same as folder (kebab-case)
Registry key:    {domain}.{sub-domain}.{name}
                 marketing.content.copywriter
                 meta.factory.skill-creator

Display name:    Title Case with domain prefix
                 "[Marketing] Copywriter"
                 "[Meta] Skill Factory"
```

#### F. Skill Registry Schema (SQLite)

```sql
CREATE TABLE IF NOT EXISTS skills (
    id TEXT PRIMARY KEY,              -- marketing.content.copywriter
    name TEXT NOT NULL,               -- copywriter
    display_name TEXT NOT NULL,       -- [Marketing] Copywriter
    version TEXT NOT NULL DEFAULT '1.0.0',
    type TEXT NOT NULL,               -- agent|skill|connector|command|module|process
    domain TEXT NOT NULL,             -- marketing/content
    task_type TEXT,                   -- analytical|generative|transformational|orchestration
    model_tier TEXT DEFAULT 'sonnet', -- opus|sonnet|haiku
    effort_level TEXT DEFAULT 'high', -- max|high|medium|low|disabled
    thread_scope TEXT DEFAULT 'any',  -- public|topic|private|any
    context_deps TEXT,                -- JSON array of required context modules
    triggers TEXT,                    -- JSON array of trigger phrases
    status TEXT DEFAULT 'active',     -- active|deprecated|draft
    skill_path TEXT NOT NULL,         -- relative path to skill folder
    created_at TEXT NOT NULL,         -- ISO 8601
    updated_at TEXT NOT NULL          -- ISO 8601
);

CREATE INDEX idx_skills_domain ON skills(domain);
CREATE INDEX idx_skills_type ON skills(type);
CREATE INDEX idx_skills_status ON skills(status);
```

#### G. Versioning Strategy

- Semver: `MAJOR.MINOR.PATCH`
- MAJOR: breaking changes to I/O contract
- MINOR: new capabilities, backward-compatible
- PATCH: bug fixes, prompt improvements
- Version in YAML frontmatter + registry

#### H. Compatibility Contract

Кожен SKILL.md = platform-agnostic core. Runtime-specific:

| Runtime | How skill is loaded | Extra file |
|---------|-------------------|------------|
| NanoClaw | Container mount → Claude SDK | CLAUDE.md (memory) |
| Claude Code | `.claude/skills/[name]/` | — |
| Claude.ai | Project Custom Instructions | Knowledge Base uploads |
| Cowork | Agent instruction | — |

**Constraint**: SKILL.md itself MUST work on ALL 4 runtimes without modification.

### 2.2 Excluded (not in this TZ)

- Actual skill content (writing real skills = TZ-0.3 Template Factory)
- Evaluation rubric scoring (= TZ-0.2)
- Handoff protocol between agents (= TZ-0.4)
- Output format templates per task type (= TZ-0.5)
- Process templates (= TZ-0.6)
- Forum thread hierarchy implementation (= TZ-1.4)
- SQLite canonical store implementation (= TZ-1.2)
- Context modules content (= TZ-1.2 schema, Phase 4 flows)

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] `SKILL.md` template file exists with all 5 sandwich sections
- [ ] YAML frontmatter schema validated (all required fields present)
- [ ] Taxonomy matrix documented: 6 domains × 6 functions, MECE verified
- [ ] Marketing sub-domains: all 15 chain positions mapped
- [ ] Naming convention defined with examples for each type
- [ ] SQLite registry schema DDL ready (skills table + indexes)
- [ ] Versioning strategy documented (semver rules)
- [ ] Compatibility matrix: 4 runtimes × how skill loads
- [ ] At least 1 example skill folder as reference implementation
- [ ] 10 Design Principles documented (from §0.9)

### Should Pass (P1)

- [ ] `scripts/validate_skill.ts` — validates SKILL.md frontmatter against schema
- [ ] Context dependency resolution documented
- [ ] Thread scope enforcement rules defined
- [ ] Trigger phrase index: all triggers unique (no collisions)

### Nice to Have (P2)

- [ ] Auto-complete for domain/sub-domain paths
- [ ] Visualization of taxonomy matrix (HTML or Mermaid)
- [ ] Skill dependency graph

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── docs/standards/
│   ├── skill-standard.md           ← Full standard document
│   ├── taxonomy-matrix.md          ← Taxonomy with all cells
│   └── naming-conventions.md       ← Detailed naming rules
├── templates/
│   └── skill/                      ← Reference skill template
│       ├── SKILL.md
│       ├── CLAUDE.md
│       ├── references/
│       ├── scripts/
│       └── assets/
├── src/store/schema/
│   └── skills.sql                  ← Registry DDL
└── scripts/
    └── validate-skill.ts           ← Frontmatter validator
```

### 4.2 Key References to Read

| Source | Path | What to Extract |
|--------|------|-----------------|
| Architecture §0.2 | `docs/architecture/phase-0-foundation.md` L44-156 | Skill file structure, sandwich, compatibility |
| Architecture §0.3 | Same file L160-269 | Taxonomy matrix, domains, functions, MVP cells |
| Architecture §0.9 | Same file L763-812 | 10 Design Principles |
| Architecture §0.10 | Same file L816-870 | 17 Context Modules list |
| Anthropic Skills Report | `Analysis_reports_md/anthropic_skills_analysis.md` | Top-10 patterns, frontmatter format |
| NanoClaw DB | `src/db.ts` | SQLite patterns, migration style |
| Skills index | `.claude/skills/_index.md` | Current plugin skills reference |
| Anthropic Guide | `docs/context_doc/My_skill_and_insite/skill_antropic Complete Guide.md` | Official guide |
| MECE Matrix | `docs/context_doc/My_skill_and_insite/` | Marketing Chain v3 |

### 4.3 Implementation Strategy

1. Write `docs/standards/skill-standard.md` — translate §0.2 into spec
2. Write `docs/standards/taxonomy-matrix.md` — full 6×6 grid with MVP cells
3. Create `templates/skill/` reference implementation
4. Write SQLite DDL in `src/store/schema/skills.sql`
5. Write `scripts/validate-skill.ts` — frontmatter validator

### 4.4 Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Over-engineering standard | Skills too rigid | Keep SKILL.md <500 lines |
| Taxonomy too granular | Sub-domains change | MECE at domain level, subs advisory |
| 4-runtime compat constrains | NanoClaw loses value | CLAUDE.md = NanoClaw extras |
| Naming collisions at scale | 30+ skills conflict | Registry enforces unique IDs |

---

## 5. Testing

### 5.1 Validation Checklist

```bash
# Validate skill-standard covers all sections
grep -c "HEADER.*QUICK REF.*CORE.*OUTPUT.*CRITICAL" docs/standards/skill-standard.md

# Validate taxonomy has 6 domains
grep -c "marketing/\|dev-ops/\|visual/\|data/\|communication/\|meta/" \
  docs/standards/taxonomy-matrix.md

# Validate SQLite schema
sqlite3 :memory: < src/store/schema/skills.sql

# Run frontmatter validator on template
npx ts-node scripts/validate-skill.ts templates/skill/SKILL.md
```

### 5.2 Integration Test

1. Create sample skill using template → passes validate-skill.ts
2. Register skill in SQLite → SELECT returns correct fields
3. Load SKILL.md in Claude Code → triggers on matching phrase
4. Load SKILL.md in NanoClaw container → CLAUDE.md works

---

## 6. Definition of Done

- [ ] Standard document written and reviewed
- [ ] Taxonomy matrix complete (6×6 + marketing sub-domains)
- [ ] Template skill folder created
- [ ] SQLite DDL tested
- [ ] validate-skill.ts passes on template
- [ ] 1 real skill passes full validation
- [ ] SPEC-INDEX.md updated: TZ-0.1 = DONE

---

_Cross-references: TZ-0.2 (evaluation rubric), TZ-0.3 (template factory), TZ-1.2 (canonical store)_
