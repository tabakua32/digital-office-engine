# TASK-04: Синтез → Дизайн Skill Factory

## МЕТА
Синтезувати ВСІ дослідження (TASK 01-03) з власними артефактами
→ спроектувати Skill Factory яка ГЕНЕРУЄ agent skills з нуля.

## КОНТЕКСТ
Skill Factory = прокачаний skill-architect.
Вхід: позиція з таблиці 77 + Marketing Chain ланка.
Вихід: повний NanoClaw-ready agent skill.

## INPUT FILES

### Результати досліджень:
```
anthropic_skills_analysis.md    ← з TASK-01
system_prompts_analysis.md      ← з TASK-02
opensource_skills_triage.md     ← з TASK-03
```

### Власні артефакти (ПРОЧИТАЙ ПОВНІСТЮ кожен):
```
YAKOMANDA_Agent_Prompt_System_v1.md   ← 52 блоки, Decision Matrix, Bias Catalog
Marketing_Chain_v3_2026.md            ← 14 ланок, frameworks, evidence grades
NanoClaw_architecture.md              ← контейнери, IPC, CLAUDE.md, groups
MECE_Marketing_Matrix_v5.xlsx         ← 77 позицій, департаменти, ролі
MECE_Claude_ecosystem.md              ← інструменти Claude, комбінації, JTBD

# Наявні skills (прочитай SKILL.md + references/):
skill-architect/                      ← БАЗОВИЙ скіл який ми АПГРЕЙДИМО
prompt-enhancer/                      ← вразливості, detection patterns
```

### Когнітивні моделі (якщо є окремим файлом):
```
cognitive_models.md                   ← Аристотельські питання, MECE, інші
```

## ЗАДАЧА

### Крок 1: Consolidated Pattern Library (1 год)
Об'єднай патерни з ТРЬОХ досліджень у одну таблицю:

```
| # | PATTERN | SOURCE | PRIORITY | NANOCLAW ADAPTATION |
|---|---------|--------|----------|---------------------|
| 1 | Sandwich structure | Anthropic skills + skill-architect | 🔴 | Перші 20% + останні 10% SKILL.md |
| 2 | ... | ... | ... | ... |
```

Категорії:
- FORMAT patterns (структура файлу)
- ORCHESTRATION patterns (делегування, handoff)
- SAFETY patterns (boundaries, escalation)
- OUTPUT patterns (формат виходу)
- MEMORY patterns (контекст між сесіями)
- QUALITY patterns (self-check, gates)

### Крок 2: Gap Analysis (1 год)

#### 2a. Що ПОТРІБНО для 77 marketing agents:
Витягни з ЯКОМАНДА + Marketing Chain + NanoClaw:
```
REQUIREMENT: [що потрібно]
SOURCE: [ЯКОМАНДА блок / Chain ланка / NanoClaw constraint]
PRIORITY: [🔴 CRITICAL | 🟡 HIGH | 🟢 NICE]
```

#### 2b. Що вже ПОКРИТО:
Перевір кожну вимогу проти наявних інструментів:
```
REQUIREMENT → COVERED BY [skill-architect? prompt-enhancer? Anthropic pattern?]
```

#### 2c. Що НЕ ПОКРИТО (ГЕПИ):
```
GAP: [що відсутнє]
IMPACT: [що станеться якщо не закрити]
SOLUTION: [як закрити — створити / адаптувати / дослідити]
EFFORT: [LOW | MED | HIGH]
```

### Крок 3: Проектування 4 нових артефактів (2 год)

#### 3a. Handoff Contract Standard
```yaml
# handoff_contract_standard.md
PURPOSE: Стандартний формат передачі даних між NanoClaw агентами

SCHEMA:
  handoff:
    from_agent: string        # хто передає
    to_agent: string          # хто отримує
    task_type: enum           # analytical | generative | transformational
    input:
      data: object            # що передається
      format: string          # markdown | json | csv | text
      confidence: float       # 0.0-1.0 — наскільки from_agent впевнений
      evidence_grade: enum    # NOBEL | PR | IV | PP | HEUR | DISC
    output_expected:
      format: string
      schema: object          # JSON schema очікуваного виходу
    constraints:
      tone_isolation: bool    # ігнорувати тон вхідного документа
      cascade_check: bool     # перевірити confidence upstream
      max_tokens: int         # бюджет контексту
    error:
      on_low_confidence: enum # flag | retry | escalate_to_human
      on_format_mismatch: enum
      on_timeout: enum

EXAMPLES:
  - analyst → strategist (competitive data → positioning recommendation)
  - strategist → copywriter (positioning → ad copy)
  - orchestrator → sub-agent (task decomposition → execution)
```

#### 3b. Output Templates (4 типи)
Для кожного типу створи template:

**ANALYTICAL** (competitor research, market analysis, audit):
```
- Confidence calibration per claim
- Evidence grade per source
- Uncertainty explicit ("не знайдено" ≠ "не існує")
- Structured sections: Executive Summary → Findings → Evidence → Gaps → Recommendations
```

**GENERATIVE** (copy, content, email sequences):
```
- Brand voice self-check rubric (перед видачею)
- Awareness level tag (Schwartz)
- Bias activation tag (які біаси активовано)
- Варіанти (мінімум 2-3 за замовчуванням)
```

**TRANSFORMATIONAL** (reformat, adapt, translate tone):
```
- Input validation checklist
- Output validation checklist
- Diff summary (що змінено і чому)
- Strict I/O schema
```

**ORCHESTRATION** (routing, delegation, synthesis):
```
- Routing table: task type → sub-agent
- Handoff contracts per sub-agent
- Aggregation rules (як збирати результати)
- Fallback strategy (якщо sub-agent fails)
```

#### 3c. Position → Skill Mapping Table
```
| # | Position | Dept | Chain Link | Task Type | Key Frameworks | Model | Bias Set |
|---|----------|------|------------|-----------|----------------|-------|----------|
| 1 | Market Intelligence Analyst | MI | ① | analytical | TAM/SAM/SOM, Porter 5, PESTEL | Sonnet | confirmation, anchoring |
| 2 | ... | ... | ... | ... | ... | ... | ... |
```
77 рядків. Використай MECE_Marketing_Matrix_v5.xlsx як основу.

### Крок 4: Архітектура Skill Factory (1 год)

Спроектуй ПОВНУ архітектуру:

```
nanoclaw-skill-factory/
├── SKILL.md                          ← Головний workflow (<500 рядків)
│                                        5 фаз: SCOPE → DESIGN → BUILD → VERIFY → PACKAGE
│
├── references/
│   ├── format-patterns.md            ← Consolidated patterns з крок 1
│   ├── format-standard.md            ← NanoClaw agent skill стандарт
│   ├── handoff-contracts.md          ← З крок 3a
│   ├── vulnerability-shields.md      ← З prompt-enhancer (адаптовано)
│   ├── marketing-context.md          ← Chain ланки + frameworks + evidence
│   ├── yakomanda-blocks.md           ← 52 блоки з Decision Matrix
│   ├── cognitive-models.md           ← Аристотель, MECE, thinking frameworks
│   ├── position-mapping.md           ← З крок 3c
│   ├── nanoclaw-constraints.md       ← Container, IPC, CLAUDE.md, groups
│   └── output-templates/
│       ├── analytical.md
│       ├── generative.md
│       ├── transformational.md
│       └── orchestration.md
│
├── scripts/
│   ├── audit_skill.py                ← Автоматична перевірка готового скіла
│   └── generate_skill_skeleton.py    ← Генерація скелету з position-mapping
│
└── assets/
    └── skill-template.md             ← Порожній шаблон NanoClaw agent skill
```

SKILL.md WORKFLOW:
```
PHASE 1 — SCOPE:
  Input: позиція # з mapping table
  → Автоматично підтягує: chain link, task type, frameworks, model tier, bias set
  → Підтягує task checklist з TASK-03 (якщо є для цього типу)

PHASE 2 — DESIGN:
  → Вибирає ЯКОМАНДА blocks за Decision Matrix
  → Вибирає vulnerability shields за task type
  → Вибирає output template за task type
  → Визначає handoff contracts (input від кого, output кому)

PHASE 3 — BUILD:
  → Генерує SKILL.md за format-standard
  → Sandwich structure: critical info перші 20% + останні 10%
  → Вбудовує output template
  → Вбудовує quality gates
  → Генерує CLAUDE.md template (пам'ять)

PHASE 4 — VERIFY:
  → 3 test prompts: ideal case, edge case, adversarial case
  → Self-check за audit_skill.py критеріями
  → Handoff contract validation (input/output schemas consistent)

PHASE 5 — PACKAGE:
  → Фінальна структура файлів
  → NanoClaw-ready (container mount points, IPC capabilities)
  → Документація для оператора
```

## OUTPUT
Файли:
1. `consolidated_patterns.md` (крок 1)
2. `gap_analysis.md` (крок 2)
3. `handoff_contract_standard.md` (крок 3a)
4. `output_templates/analytical.md` (крок 3b)
5. `output_templates/generative.md` (крок 3b)
6. `output_templates/transformational.md` (крок 3b)
7. `output_templates/orchestration.md` (крок 3b)
8. `position_skill_mapping.md` (крок 3c)
9. `skill_factory_architecture.md` (крок 4)

## QUALITY GATES
- [ ] Consolidated patterns ≥ 30 патернів з категоризацією
- [ ] Gap analysis покриває ВСІ 🔴 CRITICAL вимоги
- [ ] Handoff contract має 3+ робочих приклади
- [ ] Кожен output template має self-check rubric
- [ ] Position mapping має всі 77 рядків
- [ ] Architecture SKILL.md workflow логічно послідовний
- [ ] Все прив'язане до NanoClaw constraints (container, IPC, CLAUDE.md)
