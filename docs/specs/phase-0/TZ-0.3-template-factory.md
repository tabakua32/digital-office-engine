# TZ-0.3: Template Factory

> **Phase**: 0 — Foundation Layer
> **Priority**: P0
> **Sessions**: 2-3
> **Dependencies**: TZ-0.1 (Skill Standard — defines structure to generate)
> **Verdict**: ADAPT 45% | BUILD 35% | COPY 20%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.2, §0.3, §0.8 (Process #5)

---

## 1. Мета

Створити scaffold-генератор, який автоматично генерує повну файлову
структуру нового скіла відповідно до стандарту TZ-0.1. Кожен тип
(agent/skill/connector/command/module/process) має свій шаблон з
правильними секціями, placeholder-ами для контенту, та готовою
структурою папок.

**Без цього ТЗ**: кожен новий скіл створюється вручну → помилки
у структурі → не проходить evaluation → повторна робота.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. 6 Template Types (per function type)

**1. Agent Template**

```
[agent-name]/
├── SKILL.md                    ← agent-specific sections
│   ├── HEADER: type=agent, effort=max/high, model=opus/sonnet
│   ├── QUICK REF: delegation table, sub-agent routing
│   ├── CORE: planning logic, decision tree, escalation rules
│   ├── OUTPUT: orchestration format (step status + aggregation)
│   └── CRITICAL: boundary enforcement, cascade check required
├── references/
│   └── delegation-matrix.md    ← which skills this agent calls
├── CLAUDE.md                   ← persistent memory: decisions, context
└── assets/
    └── examples/
        └── sample-delegation.json
```

**2. Skill Template**

```
[skill-name]/
├── SKILL.md                    ← task-focused sections
│   ├── HEADER: type=skill, model=sonnet/haiku
│   ├── QUICK REF: routing table, I/O contract
│   ├── CORE: process steps (numbered), quality gates
│   ├── OUTPUT: task-type format (analytical/generative/etc)
│   └── CRITICAL: anti-hallucination, tone isolation
├── references/
│   └── methodology.md          ← detailed process if >500 lines
├── CLAUDE.md
└── assets/
    ├── templates/
    │   └── output-template.md  ← pre-built output format
    └── examples/
        ├── good-output.md
        └── bad-output.md       ← anti-pattern example
```

**3. Connector Template**

```
[connector-name]/
├── SKILL.md                    ← MCP bridge configuration
│   ├── HEADER: type=connector, model=N/A
│   ├── QUICK REF: API endpoints, auth method, rate limits
│   ├── CORE: available tools (MCP tool definitions)
│   ├── OUTPUT: raw API response → structured format
│   └── CRITICAL: error codes, fallback behavior
└── references/
    └── api-docs.md             ← external API documentation summary
```

**4. Command Template**

```
[command-name]/
├── SKILL.md                    ← slash-command handler
│   ├── HEADER: type=command, model=haiku/disabled
│   ├── QUICK REF: trigger="/command", args, permissions
│   ├── CORE: parse args → validate → execute → respond
│   ├── OUTPUT: compact response format
│   └── CRITICAL: permission check (owner-only? all?)
└── assets/
    └── examples/
        └── usage.md
```

**5. Module Template**

```
[module-name]/
├── SKILL.md                    ← context data block
│   ├── HEADER: type=module, model=N/A
│   ├── CONTENT: structured data (markdown or JSON)
│   └── METADATA: source, freshness, update frequency
└── references/
    └── schema.md               ← data schema documentation
```

**6. Process Template**

```
[process-name]/
├── SKILL.md                    ← multi-step workflow recipe
│   ├── HEADER: type=process, model=sonnet
│   ├── QUICK REF: trigger, thread targeting, agent list
│   ├── CORE: step-by-step recipe with HITL points
│   ├── OUTPUT: orchestration status format
│   └── CRITICAL: rollback on failure, partial result handling
├── references/
│   └── step-details.md         ← detailed per-step instructions
└── assets/
    └── templates/
        └── workflow-status.md  ← status report template
```

#### B. Scaffold Generator Script

```bash
# Usage
npx ts-node scripts/create-skill.ts \
  --type skill \
  --domain marketing/content \
  --name copywriter \
  --task-type generative \
  --model sonnet

# Output: creates marketing-content-copywriter/ with all files
```

**Generator logic:**
1. Parse args → validate domain exists in taxonomy
2. Select template by type
3. Copy template files → replace `{{placeholders}}`
4. Generate YAML frontmatter from args
5. Create folder structure
6. Register in SQLite skills table (draft status)
7. Print creation summary + "next steps" guide

#### C. Placeholder System

Templates use `{{placeholder}}` syntax:

```
{{skill_name}}       → copywriter
{{domain}}           → marketing/content
{{display_name}}     → [Marketing] Copywriter
{{registry_key}}     → marketing.content.copywriter
{{model_tier}}       → sonnet
{{task_type}}        → generative
{{context_deps}}     → product/spec, audience/icp, brand/voice
{{thread_scope}}     → topic
{{version}}          → 1.0.0
{{author}}           → nanoclaw
{{created_date}}     → 2026-03-15
```

#### D. Reference Implementation Skills (3 real examples)

Create 3 working skills to validate templates:

| Skill | Type | Domain | Purpose |
|-------|------|--------|---------|
| `meta-skill-factory` | skill | meta/ | Creates other skills (dogfooding) |
| `marketing-content-copywriter` | skill | marketing/content | Writes articles |
| `dev-ops-skill-auditor` | agent | dev-ops/ | Evaluates skill quality |

### 2.2 Excluded

- Content for 30+ domain skills (built incrementally later)
- CI/CD skill deployment pipeline (= TZ-0.7)
- Handoff protocol in agent templates (= TZ-0.4)
- Output format details per task type (= TZ-0.5, referenced but not defined here)

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] 6 template types created (agent/skill/connector/command/module/process)
- [ ] Each template has correct sandwich structure per TZ-0.1
- [ ] `scripts/create-skill.ts` generates valid skill folder from args
- [ ] Generated skill passes `audit-skill.ts` (TZ-0.2) with score >= 70
- [ ] Placeholder system works (all `{{placeholders}}` replaced)
- [ ] 3 reference implementation skills created and pass evaluation
- [ ] YAML frontmatter auto-generated correctly

### Should Pass (P1)

- [ ] Interactive mode: script asks questions if args missing
- [ ] Auto-register in SQLite skills table on creation
- [ ] `--from-existing` flag: import existing SKILL.md into standard format
- [ ] Generated CLAUDE.md has correct persistent memory template

### Nice to Have (P2)

- [ ] Web UI for skill creation (via bot command)
- [ ] Template versioning (upgrade existing skills to new standard)

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── templates/
│   ├── agent/              ← Agent template files
│   │   ├── SKILL.md
│   │   ├── CLAUDE.md
│   │   └── references/
│   ├── skill/              ← Skill template files
│   ├── connector/
│   ├── command/
│   ├── module/
│   └── process/
├── skills/                 ← Created skills go here
│   ├── meta-skill-factory/
│   ├── marketing-content-copywriter/
│   └── dev-ops-skill-auditor/
└── scripts/
    └── create-skill.ts     ← Scaffold generator
```

### 4.2 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| 18 Anthropic Plugins | `docs/context_doc/claude_skills/` | Structure of real skills |
| Architecture §0.8 | `docs/architecture/phase-0-foundation.md` L700-758 | Process #5: Skill Creation |
| NanoClaw agents | `src/agents/` or `src/groups/` | Existing agent patterns |
| Anthropic analysis | `Analysis_reports_md/anthropic_skills_analysis.md` | Top-10 skill patterns |
| Marketing skills | `docs/context_doc/marketing_skills_repo/` | 24 skill collections |

### 4.3 Risks

| Risk | Mitigation |
|------|------------|
| Templates too rigid | Keep templates as starting points, not constraints |
| Placeholder collision | Use `{{` prefix consistently, validate no leftover |
| 3 reference skills scope creep | Keep each skill minimal (focus on structure, not content depth) |

---

## 5. Testing

```bash
# Generate skill from each type
for type in agent skill connector command module process; do
  npx ts-node scripts/create-skill.ts --type $type --domain meta --name test-$type
  npx ts-node scripts/audit-skill.ts skills/meta-test-$type/
done

# All 6 should pass with score >= 70

# Verify reference skills
npx ts-node scripts/audit-skill.ts skills/meta-skill-factory/
npx ts-node scripts/audit-skill.ts skills/marketing-content-copywriter/
npx ts-node scripts/audit-skill.ts skills/dev-ops-skill-auditor/
# All 3 should score >= 85
```

---

## 6. Definition of Done

- [ ] 6 template types created
- [ ] create-skill.ts generates valid skills
- [ ] 3 reference skills pass evaluation (85+)
- [ ] Placeholder system documented
- [ ] SPEC-INDEX.md updated: TZ-0.3 = DONE

---

_Cross-references: TZ-0.1 (standard to follow), TZ-0.2 (evaluation to pass), TZ-0.4 (handoff in agent template), TZ-0.5 (output format in skill template)_
