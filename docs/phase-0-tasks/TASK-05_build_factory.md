# TASK-05: Побудова Skill Factory

## МЕТА
Побудувати nanoclaw-skill-factory — скіл який ГЕНЕРУЄ agent skills з нуля.
Це АПГРЕЙД skill-architect, спеціалізований під NanoClaw marketing department.

## КОНТЕКСТ
Після цього таска у тебе буде ІНСТРУМЕНТ.
Далі (TASK-06) ти прогониш через нього 5 тестових агентів.
Якщо щось зламається — повернешся сюди і виправиш.

## INPUT FILES
```
# Результати TASK-04 (ВСІ файли):
consolidated_patterns.md
gap_analysis.md
handoff_contract_standard.md
output_templates/analytical.md
output_templates/generative.md
output_templates/transformational.md
output_templates/orchestration.md
position_skill_mapping.md
skill_factory_architecture.md

# Базовий скіл (читай ПОВНІСТЮ — це основа яку апгрейдимо):
skill-architect/SKILL.md
skill-architect/references/*

# Вразливості (читай ПОВНІСТЮ):
prompt-enhancer/SKILL.md
prompt-enhancer/references/*

# Доменні знання:
YAKOMANDA_Agent_Prompt_System_v1.md
Marketing_Chain_v3_2026.md
NanoClaw_architecture.md
```

## ЗАДАЧА

### Крок 1: Створи file structure
```bash
mkdir -p nanoclaw-skill-factory/references/output-templates
mkdir -p nanoclaw-skill-factory/scripts
mkdir -p nanoclaw-skill-factory/assets
```

### Крок 2: Напиши SKILL.md (головний файл)

ВИМОГИ:
- Максимум 500 рядків (progressive disclosure — деталі у references/)
- Sandwich structure: 🔴 critical у перших 20% і останніх 10%
- Конкретні інструкції > абстрактні принципи
- Кожна фаза має чіткий INPUT → PROCESS → OUTPUT

СТРУКТУРА SKILL.md:
```markdown
# NanoClaw Skill Factory

## QUICK REFERENCE (перші 5% — routing table)
| Input | Action |
|-------|--------|
| "створи агента для позиції #X" | → Phase 1-5 повний цикл |
| "аудит існуючого скіла" | → Phase 4 тільки |
| "згенеруй скелет" | → Phase 1-2, потім ручна робота |

## PHASE 1: SCOPE (що будуємо)
Input: номер позиції АБО опис ролі
→ Lookup у position_skill_mapping.md
→ Отримуємо: chain link, task type, frameworks, model, biases
→ Підтягуємо task checklist (з opensource_skills_triage.md якщо є)
Output: skill_spec (JSON або structured markdown)

## PHASE 2: DESIGN (архітектура скіла)
Input: skill_spec
→ Вибір ЯКОМАНДА blocks (references/yakomanda-blocks.md → Decision Matrix)
→ Вибір vulnerability shields (references/vulnerability-shields.md)
→ Вибір output template (references/output-templates/{task_type}.md)
→ Визначення handoff contracts (references/handoff-contracts.md)
→ Визначення NanoClaw constraints (references/nanoclaw-constraints.md)
Output: skill_design (повний blueprint)

## PHASE 3: BUILD (написання)
Input: skill_design
→ Генерація SKILL.md за format-standard.md
→ Sandwich structure enforcement
→ Вбудовування output template
→ Вбудовування quality gates
→ Генерація CLAUDE.md template
→ Генерація references/ якщо потрібно
Output: повна файлова структура скіла

## PHASE 4: VERIFY (перевірка)
Input: готовий скіл
→ Structural check (format-standard compliance)
→ Content check (ЯКОМАНДА required blocks present)
→ Vulnerability check (shields present for task type)
→ Handoff check (input/output schemas consistent)
→ 3 test scenarios: ideal, edge, adversarial
→ Token budget check (SKILL.md < 500 lines)
Output: verification report + PASS/FAIL

## PHASE 5: PACKAGE (фіналізація)
Input: verified скіл
→ NanoClaw file structure
→ Container mount points documented
→ IPC capabilities documented
→ Operator documentation
Output: ready-to-deploy agent skill

## CRITICAL RULES (останні 10%)
[Sandwich: повтори найважливіше]
```

### Крок 3: Напиши references/

Кожен файл — self-contained, Claude Code може прочитати його окремо:

```
references/
├── format-standard.md          ← Як має виглядати NanoClaw agent skill
│                                  (секції, порядок, naming conventions)
├── format-patterns.md          ← Consolidated patterns з TASK-04
├── handoff-contracts.md        ← Standard + приклади з TASK-04
├── vulnerability-shields.md    ← Адаптовано з prompt-enhancer:
│                                  per-task-type shields, detection signals,
│                                  anti-sycophancy, confidence calibration
├── marketing-context.md        ← Chain links summary + frameworks per link
│                                  + evidence grades (compact version)
├── yakomanda-blocks.md         ← 52 blocks + Decision Matrix
│                                  (compact: block ID, назва, коли потрібен,
│                                  приклад implementation)
├── cognitive-models.md         ← Thinking frameworks для складних задач
├── position-mapping.md         ← 77 рядків таблиці з TASK-04
├── nanoclaw-constraints.md     ← Container model, CLAUDE.md format,
│                                  IPC tools, group isolation, mount points
└── output-templates/
    ├── analytical.md           ← З TASK-04
    ├── generative.md
    ├── transformational.md
    └── orchestration.md
```

### Крок 4: Напиши scripts/

```python
# scripts/audit_skill.py
# Input: шлях до agent skill directory
# Process: перевіряє compliance з format-standard
# Output: report з PASS/FAIL per criterion

CHECKS:
- [ ] SKILL.md існує і < 500 рядків
- [ ] Sandwich structure (critical info in first 20% and last 10%)
- [ ] Identity block present (ЯКОМАНДА I1-I4)
- [ ] Boundaries block present (ЯКОМАНДА P2)
- [ ] Anti-hallucination block present (ЯКОМАНДА P14)
- [ ] Output template embedded
- [ ] Quality gates defined
- [ ] Handoff contract defined (input + output schemas)
- [ ] CLAUDE.md template present
- [ ] NanoClaw mount points documented
```

```python
# scripts/generate_skill_skeleton.py
# Input: position number (1-77)
# Process: reads position-mapping.md → generates skeleton
# Output: directory structure з placeholder SKILL.md
```

### Крок 5: Напиши assets/skill-template.md
Порожній шаблон NanoClaw agent skill з усіма обов'язковими секціями
і коментарями-підказками що писати в кожній.

## OUTPUT
```
nanoclaw-skill-factory/
├── SKILL.md                    ← < 500 рядків
├── references/                 ← 10+ файлів
│   └── output-templates/       ← 4 файли
├── scripts/                    ← 2 файли
└── assets/                     ← 1 файл
```

## QUALITY GATES
- [ ] SKILL.md < 500 рядків
- [ ] SKILL.md має sandwich structure
- [ ] Кожна phase має чіткий INPUT → PROCESS → OUTPUT
- [ ] ВСІ references файли написані і non-empty
- [ ] Scripts працюють (python scripts/audit_skill.py --help)
- [ ] Template має ВСІ обов'язкові секції
- [ ] Можна прочитати ТІЛЬКИ SKILL.md і зрозуміти як користуватись
- [ ] Progressive disclosure працює: деталі у references, не у SKILL.md
