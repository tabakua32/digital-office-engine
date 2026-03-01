# TZ-0.6: Process Templates

> **Phase**: 0 — Foundation Layer
> **Priority**: P2
> **Sessions**: 1-2
> **Dependencies**: TZ-0.1 (types), TZ-0.4 (handoff), TZ-0.5 (output format)
> **Verdict**: ADAPT 40% | BUILD 40% | COPY 20%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.8

---

## 1. Мета

Визначити формат мульти-агентних workflow (processes) — рецептів,
за якими Orchestrator agent координує виконання складних задач
(campaign launch, content pipeline, client onboarding тощо).
Process = РЕЦЕПТ, не агент. Orchestrator виконує рецепт.

**Без цього ТЗ**: мульти-агентні pipeline виконуються ad hoc →
пропускаються кроки → HITL точки не визначені → немає rollback.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Process Definition Format

```yaml
# process-definition.yaml
---
name: campaign-launch
display_name: "Campaign Launch"
version: "1.0.0"
type: process
domain: marketing
trigger:
  command: "/launch"
  args: "[campaign brief]"
thread:
  mode: auto-create             # auto-create | existing | any
  name_template: "📢 Campaign: {{campaign_name}}"
  close_on_complete: true
agents:
  - strategist
  - mi-analyst
  - copywriter
  - designer
  - seo-auditor
steps:
  - id: 1
    name: "Brief Analysis"
    agent: strategist
    input: "{{trigger.args}}"
    output_format: analytical
    timeout_minutes: 5
    on_failure: escalate

  - id: 2
    name: "Market Research"
    agent: mi-analyst
    input: "step.1.output"
    output_format: analytical
    timeout_minutes: 10
    on_failure: flag_and_continue

  - id: 3
    name: "Strategy Draft"
    agent: strategist
    input: "step.1.output + step.2.output"
    output_format: analytical
    hitl: true                  # HUMAN APPROVAL REQUIRED
    hitl_prompt: "Review strategy before content creation"
    timeout_minutes: null       # wait indefinitely for human

  - id: 4
    name: "Content Creation"
    agent: copywriter
    input: "step.3.output (approved)"
    output_format: generative
    timeout_minutes: 15
    on_failure: retry_once

  - id: 5
    name: "SEO Optimization"
    agent: seo-auditor
    input: "step.4.output"
    output_format: transformational
    timeout_minutes: 5

  - id: 6
    name: "Go-Live Check"
    agent: strategist
    input: "step.5.output"
    output_format: orchestration
    hitl: true
    hitl_prompt: "Final approval before publishing"

cost_estimate:
  model_mix: "80% Sonnet, 20% Haiku"
  tokens_estimate: "~50K-100K"
  cost_estimate: "$2-5"
---
```

#### B. 5 Canonical Process Definitions

| # | Process | Trigger | Thread | Agents | HITL Points | Est. Cost |
|---|---------|---------|--------|--------|-------------|-----------|
| 1 | **Campaign Launch** | `/launch [brief]` | auto-create | 5-7 | Step 3, 6 | $2-5 |
| 2 | **Content Pipeline** | `/content [topic]` | existing "✍️ Контент" | 4-5 | Step 4, 7 | $0.50-1.50 |
| 3 | **Client Onboarding** | new group added | "🔧 Система" | 3 (meta/) | Step 6 | $1-3 |
| 4 | **Competitive Intelligence** | cron (weekly) | "📊 Аналітика" | 2-3 | none | $0.50-1 |
| 5 | **Skill Creation** | "create skill for X" | "🔧 Система" | 3 (meta/) | Step 4, 6 | $1-2 |

#### C. Process Execution Engine Requirements

For the orchestrator agent to execute processes:

1. **Load process definition** from YAML
2. **Execute steps sequentially** (or parallel where marked)
3. **Pass handoffs** between steps (TZ-0.4 format)
4. **Pause at HITL points** → send approval request to user
5. **Handle failures** per step's `on_failure` rule
6. **Track status** → orchestration output format (TZ-0.5)
7. **Target correct thread** → `message_thread_id` from definition

#### D. Task Lifecycle States

```
CREATED → QUEUED → RUNNING → [HITL_WAITING] → COMPLETED
                          └→ FAILED → [RETRY] → RUNNING
                          └→ TIMEOUT → ESCALATED
```

#### E. Scheduled/Cyclic Tasks

```yaml
schedule:
  type: cron                    # cron | interval | one-time
  value: "0 9 * * 1"           # every Monday at 9:00
  timezone: "Europe/Kyiv"
```

### 2.2 Excluded

- Process execution engine implementation (= TZ-4.1 + TZ-4.8)
- Forum thread auto-creation API (= TZ-2.5 Forums)
- HITL button rendering (= TZ-2.3 HITL & Streaming)
- Cost tracking implementation (= TZ-3.2 Cost Framework)
- Actual content for 5 processes (just structure + examples)

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] Process definition YAML schema documented
- [ ] 5 canonical processes defined with all fields
- [ ] Task lifecycle states diagram
- [ ] HITL integration points documented (when to pause)
- [ ] Error handling: 4 strategies (escalate/retry/flag/abort)
- [ ] Schedule format: cron + interval + one-time
- [ ] At least 1 process validates against YAML schema

### Should Pass (P1)

- [ ] Step dependency graph (parallel execution support)
- [ ] Cost estimation formula per process
- [ ] Process versioning (upgrade running processes)

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── docs/standards/
│   └── process-templates.md        ← Process format standard
├── processes/
│   ├── campaign-launch.yaml
│   ├── content-pipeline.yaml
│   ├── client-onboarding.yaml
│   ├── competitive-intelligence.yaml
│   └── skill-creation.yaml
└── src/types/
    └── process.ts                  ← TypeScript interfaces
```

### 4.2 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| Architecture §0.8 | `docs/architecture/phase-0-foundation.md` L700-758 | 5 canonical processes |
| NanoClaw scheduler | `src/db.ts` (scheduled_tasks table) | Existing task lifecycle |
| Marketing skills | `docs/context_doc/marketing_skills_repo/` | Workflow patterns |

---

## 5. Testing

```bash
# Validate each process definition
for proc in processes/*.yaml; do
  npx ts-node scripts/validate-process.ts $proc
done

# Verify task lifecycle state machine
npx vitest run tests/process/lifecycle.test.ts
```

---

## 6. Definition of Done

- [ ] Process format documented
- [ ] 5 YAML definitions created
- [ ] TypeScript interfaces exported
- [ ] Schema validation works
- [ ] SPEC-INDEX.md updated: TZ-0.6 = DONE

---

_Cross-references: TZ-0.4 (handoff between steps), TZ-0.5 (output format per step), TZ-4.1 (flow engine executes), TZ-4.8 (scheduled workflows)_
