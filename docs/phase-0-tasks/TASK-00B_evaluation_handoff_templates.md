# TASK-00B: Evaluation + Handoff + Output + Process Templates

## МЕТА
Створити 4 інфраструктурних артефакти які ДОПОВНЮЮТЬ стандарт з TASK-00A:
- Як ОЦІНЮВАТИ скіл (evaluation)
- Як агенти СПІЛКУЮТЬСЯ (handoff)
- Як агенти ВИДАЮТЬ результат (output templates)
- Як агенти КООРДИНУЮТЬСЯ у workflows (process templates)

## КОНТЕКСТ
TASK-00A дає: що таке скіл (standard) і які типи існують (taxonomy).
TASK-00B дає: як оцінити, як з'єднати, як форматувати вихід, як оркеструвати.
Разом = повний LAYER 1 Foundation (крім Skill Factory яка будується пізніше).

## INPUT

### З TASK-00A (прочитай ОБОВ'ЯЗКОВО):
```
foundation/
├── skill_standard.md
└── skill_taxonomy.md
```

### Наші артефакти:
```
YAKOMANDA_Agent_Prompt_System_v1.md     ← blocks, biases, anti-patterns
prompt-enhancer/SKILL.md + references/  ← vulnerability detection, task types
Marketing_Chain_v3_2026.md              ← evidence grades, frameworks
NanoClaw_architecture.md                ← IPC, containers, groups
```

### Anthropic references:
```
claude-cookbooks-main/                  ← output format patterns
claude-agent-sdk-typescript-main/       ← agent communication patterns
[official plugins]/                     ← output templates з plugins
```

### Завершені дослідження:
```
claude_prompts_analysis.md              ← TASK-02
anthropic_skills_analysis.md            ← TASK-01 (якщо вже виконано)
non_claude_prompts_analysis.md          ← TASK-02B (якщо вже виконано)
```

## ЗАДАЧА

### Крок 1: Evaluation Framework (1.5 год)

```markdown
# evaluation_framework.md

## Scoring Rubric (для кожного скіла)

### A. STRUCTURAL (формат) — 20 балів
A1. File structure matches standard    [0-4]
A2. SKILL.md < 500 lines              [0-4]
A3. Sandwich structure                 [0-4]
A4. Progressive disclosure             [0-4]
A5. Naming conventions                 [0-4]

### B. CONTENT (зміст) — 30 балів
B1. Identity clear and specific        [0-5]
B2. Boundaries defined (P2)            [0-5]
B3. Anti-hallucination present (P14)   [0-5]
B4. Process steps actionable           [0-5]
B5. Quality gates concrete             [0-5]
B6. Error handling defined             [0-5]

### C. VULNERABILITY (захист) — 20 балів
C1. Anti-sycophancy shields            [0-5]
C2. Confidence calibration             [0-5]
C3. Hallucination detection signals    [0-5]
C4. Task-appropriate tone              [0-5]

### D. INTEGRATION (з'єднання) — 15 балів
D1. Input schema defined               [0-5]
D2. Output schema defined              [0-5]
D3. Context dependencies declared      [0-5]

### E. RUNTIME (сумісність) — 15 балів
E1. NanoClaw compatible                [0-5]
E2. Claude Code compatible             [0-5]
E3. Claude.ai convertible              [0-5]

## TOTAL: /100
├── 90-100: Production ready
├── 70-89:  Needs minor fixes
├── 50-69:  Needs significant rework
└── <50:    Reject and redesign

## Auto-Check Script Spec
Які перевірки можна автоматизувати (для scripts/audit_skill.py):
- A1-A5: повністю автоматизовані (file checks)
- B1-B2: частково (regex пошук ключових секцій)
- D1-D3: частково (перевірка наявності schema блоків)
- E1-E3: частково (перевірка compatibility markers)
- Решта: потребує Claude Code review (semantic)
```

### Крок 2: Handoff Protocol (1.5 год)

```markdown
# handoff_protocol.md

## Навіщо
Агент #3 видає результат → Агент #7 його споживає.
Без протоколу: "ось текст, розберися".
З протоколом: формальний контракт з типами, confidence, tone isolation.

## Schema

### Handoff Contract (JSON-like):
{
  "handoff_id": "uuid",
  "timestamp": "ISO-8601",
  "from": {
    "agent": "competitive-intelligence-analyst",
    "domain": "marketing",
    "function": "skill",
    "task_type": "analytical"
  },
  "to": {
    "agent": "positioning-strategist",
    "domain": "marketing",
    "function": "agent",
    "task_type": "analytical"
  },
  "payload": {
    "format": "markdown | json | csv | structured",
    "content": "...",
    "schema": { /* JSON schema of content structure */ },
    "metadata": {
      "confidence": 0.85,          // 0.0-1.0
      "evidence_grade": "IV",       // NOBEL|PR|IV|PP|HEUR|DISC
      "sources_count": 7,
      "data_freshness": "2026-02-27",
      "gaps": ["pricing data incomplete", "no direct interviews"],
      "assumptions": ["market size based on 2025 report"]
    }
  },
  "constraints": {
    "tone_isolation": true,         // ignore source tone
    "cascade_check": true,          // verify upstream confidence
    "max_context_tokens": 4000,     // budget for this handoff
    "required_output_format": "positioning_statement"
  },
  "error": {
    "on_low_confidence": "flag_and_continue | retry | escalate",
    "on_format_mismatch": "adapt | reject | escalate",
    "on_timeout": "partial_result | escalate"
  }
}

## NanoClaw Implementation
Як це працює через NanoClaw IPC:
- Container A записує handoff JSON у IPC_DIR/handoffs/
- Container B читає при старті
- Validation перед обробкою

## Claude Code Implementation
Як це працює через Claude Code sub-agents:
- Parent agent формує handoff у промпті sub-agent
- Sub-agent валідує input
- Sub-agent повертає output у тому ж форматі

## Claude.ai Implementation
Як це працює через Projects:
- Handoff = документ у Knowledge Base
- Наступний чат читає документ як контекст

## Приклади (мінімум 5):
1. MI Analyst → Positioning Strategist
2. Positioning → Copywriter
3. Copywriter → Designer (cross-domain)
4. VP Marketing → 3 sub-agents (fan-out)
5. 3 sub-agents → VP Marketing (fan-in, aggregation)

## Cascade Check Protocol
Коли confidence < threshold:
- 0.8+ : proceed normally
- 0.5-0.8 : flag uncertainty in output
- 0.3-0.5 : request human review
- <0.3 : reject and escalate

## Tone Isolation Protocol
Коли analytical agent отримує creative input:
- Strip tone markers
- Extract only factual claims
- Apply own tone from SKILL.md identity
```

### Крок 3: Output Templates (1.5 год)

Для кожного task type — стандартний template.
**КРИТИЧНО**: кожен template має версію для КОЖНОГО runtime.

```markdown
# output_templates/analytical.md

## Analytical Output Template
Used by: task_type = analytical (research, audit, analysis, intelligence)

### Structure:
1. Executive Summary (3-5 речень, findings + confidence)
2. Methodology (джерела, обмеження, assumptions)
3. Findings (structured, кожен finding з confidence + evidence_grade)
4. Gaps & Uncertainties (що НЕ знайдено, що потребує перевірки)
5. Recommendations (actionable, prioritized)
6. Sources (cited, graded)

### Per-Finding Format:
**Finding**: [твердження]
**Confidence**: [0.0-1.0]
**Evidence**: [NOBEL|PR|IV|PP|HEUR|DISC]
**Source**: [цитата]
**Caveat**: [якщо є]

### Self-Check Rubric (агент перевіряє себе ПЕРЕД видачею):
- [ ] Кожен finding має confidence score?
- [ ] Є розділ "що я НЕ знаю"?
- [ ] Recommendations прив'язані до findings?
- [ ] Немає тверджень без джерел?
- [ ] Tone = objective (не promotional)?

### Runtime Versions:
- NanoClaw/Claude Code: markdown файл
- Claude.ai: Artifact (markdown)
- Cowork: File Creation (docx)
- API: JSON з structured output
```

Аналогічно створи:
- `output_templates/generative.md` (copy, content, email)
- `output_templates/transformational.md` (reformat, adapt, convert)
- `output_templates/orchestration.md` (delegation, routing, aggregation)

### Крок 4: Process Templates (1 год)

```markdown
# process_templates.md

## Що таке Process
Process = orchestration workflow з кількох кроків.
Кожен крок = виклик agent/skill з handoff contract.
Process = НЕ агент. Process = РЕЦЕПТ який агент-оркестратор виконує.

## Template Format

### Process: [назва]
**Trigger**: [коли запускається]
**Owner**: [який orchestration agent керує]
**Steps**:

Step 1: [назва]
  Agent: [хто виконує]
  Input: [handoff contract — від кого або від user]
  Action: [що робить]
  Output: [handoff contract — кому]
  Gate: [умова переходу до Step 2]
  Error: [що якщо fail]

Step 2: [назва]
  ...

**Completion Criteria**: [коли процес вважається завершеним]
**Rollback**: [що якщо потрібно відкотити]

## Core Processes (створи повний template для кожного):

### 1. Campaign Launch
Trigger: "/launch [campaign brief]"
Steps: Brief validation → Market research → Strategy →
       Content creation → Design → Copy → Distribution setup →
       Analytics setup → Go-live check
~8-10 steps, 5-7 agents involved

### 2. Content Pipeline
Trigger: "/content [topic]"
Steps: Topic research → SEO analysis → Outline →
       Draft → Edit → Visual → SEO optimize →
       Format for channels → Schedule
~8-9 steps, 4-5 agents

### 3. Client Onboarding
Trigger: "new client [company]"
Steps: Company extraction → Product extraction →
       Audience extraction → Brand extraction →
       Market extraction → Module validation →
       Agent configuration → Test run
~8 steps, meta agents

### 4. Competitive Intelligence Cycle
Trigger: scheduled (weekly/monthly)
Steps: Monitor triggers → Collect data →
       Analyze changes → Generate report →
       Update market module → Notify strategist
~6 steps, 2-3 agents

### 5. Skill Creation (Factory Process)
Trigger: "create skill for [position]"
Steps: Scope → Design → Build → Verify → Package → Deploy
~6 steps, factory + dev team

## NanoClaw Implementation
Як процес запускається через NanoClaw:
- Orchestrator agent отримує trigger
- Використовує schedule_task для async steps
- Використовує send_message для notifications
- Handoff через IPC files

## Claude Code Implementation
Як процес запускається через Claude Code:
- /slash command triggers orchestrator
- Sub-agents для кожного step
- Results aggregated by parent
```

## OUTPUT
```
foundation/
├── evaluation_framework.md         ← Крок 1
├── handoff_protocol.md             ← Крок 2
├── output_templates/               ← Крок 3
│   ├── analytical.md
│   ├── generative.md
│   ├── transformational.md
│   └── orchestration.md
└── process_templates.md            ← Крок 4
```

## QUALITY GATES
- [ ] Evaluation rubric має конкретні числові критерії (не "good/bad")
- [ ] Handoff protocol має JSON schema + 5 прикладів
- [ ] Handoff має версію для КОЖНОГО runtime (NanoClaw, CC, Claude.ai, Cowork)
- [ ] 4 output templates створені, кожен з self-check rubric
- [ ] Кожен output template має runtime versions
- [ ] 5 process templates з повними step-by-step
- [ ] Process templates визначають error handling per step
- [ ] Все консистентно з skill_standard.md з TASK-00A
