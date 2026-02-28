# TASK-02B: Дослідження Non-Claude Agent System Prompts

## МЕТА
Екстрагувати orchestration, tool use та output patterns з:
Bolt, Cursor, Lovable, Manus, Replit.

Доповнення до TASK-02 (Claude prompts — вже виконано).
Фокус: що ці системи роблять ІНАКШЕ і що з цього корисне для NanoClaw.

## INPUT

### Папка з промптами:
```
/Users/God_Yurii/Downloads/AI_PROJECT/nanoclow/claude_skills/system_promts_agent_leak/
```

### Додатково шукай у:
```
/Users/God_Yurii/Downloads/AI_PROJECT/nanoclow/marketing_skills_repo/
```
Релевантні репо:
- `claude-code-system-prompts-main` (може містити й інші)
- Будь-які файли з "system prompt" або "leaked" у назві

### Якщо промптів немає локально:
```
https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools
https://github.com/thekishandev/ai-system-prompt
```

## СИСТЕМИ ДЛЯ АНАЛІЗУ

```
СИСТЕМА   │ ТИП                      │ ФОКУС АНАЛІЗУ
──────────┼──────────────────────────┼────────────────────────────────────
Manus     │ Multi-agent orchestrator │ 🔴 Task decomposition, sub-agent
          │                          │    delegation, result aggregation,
          │                          │    error recovery між агентами
──────────┼──────────────────────────┼────────────────────────────────────
Cursor    │ IDE agent (tools+code)   │ 🔴 Tool selection logic, file
          │                          │    management, context budget,
          │                          │    instruction density
──────────┼──────────────────────────┼────────────────────────────────────
Bolt      │ Full-stack code gen      │ 🟡 Code generation patterns,
          │                          │    preview/sandbox, iterative
          │                          │    refinement loop
──────────┼──────────────────────────┼────────────────────────────────────
Lovable   │ App builder              │ 🟡 Component architecture,
          │                          │    design system integration,
          │                          │    user feedback loop
──────────┼──────────────────────────┼────────────────────────────────────
Replit    │ Cloud IDE agent          │ 🟡 Environment management,
          │                          │    deployment pipeline,
          │                          │    multi-file orchestration
```

## ЗАДАЧА

### Крок 1: Знайди промпти
```bash
# Пошук у локальних папках
find /Users/God_Yurii/Downloads/AI_PROJECT/nanoclow/ \
  -iname "*system*prompt*" -o -iname "*manus*" -o -iname "*cursor*" \
  -o -iname "*bolt*" -o -iname "*lovable*" -o -iname "*replit*" \
  | grep -i -E "\.(md|txt|py|ts|json)$"
```

Для кожного знайденого:
```
SYSTEM: [назва]
FILE: [шлях]
DATE: [дата якщо відома]
SIZE: [рядки]
COMPLETENESS: [full prompt | partial | fragment]
```

### Крок 2: Аналіз по 8 вимірах (для кожної системи)

```yaml
system: "Manus"
source: "[файл]"
date: "2025-XX"
size_lines: N

# 1. IDENTITY
identity:
  role_definition: "[як визначена роль — цитата перших рядків]"
  boundaries: "[explicit заборони]"
  mission: "[місія одним реченням]"

# 2. SAFETY
safety:
  forbidden_actions: 
    - "[дія]"
  escalation_triggers:
    - "якщо [умова] → [дія]"
  refusal_patterns:
    - "[як відмовляє]"

# 3. TOOLS
tools:
  definition_format: "[inline | JSON schema | XML | окремий блок]"
  selection_logic: "[як вибирає який tool використати]"
  chaining: "[чи є послідовність tools]"
  error_on_tool_fail: "[що робить якщо tool зафейлив]"

# 4. ORCHESTRATION (особливо для Manus)
orchestration:
  task_decomposition: "[як розбиває складну задачу]"
  sub_agent_format: "[формат задачі для sub-agent]"
  result_aggregation: "[як збирає результати]"
  partial_failure: "[що робить якщо 1 з 3 sub-agents зафейлив]"

# 5. OUTPUT
output:
  format_control: "[як задає формат виходу]"
  templates: "[чи є шаблони]"
  self_check: "[чи перевіряє себе перед видачею]"

# 6. MEMORY
memory:
  between_sessions: "[як зберігає контекст]"
  file_based: "[чи є файлова пам'ять]"
  context_management: "[як керує розміром контексту]"

# 7. ERROR HANDLING
errors:
  degradation: "[стратегія деградації]"
  retry: "[чи є retry logic]"
  user_notification: "[як повідомляє юзера про проблему]"

# 8. UNIQUE (що є ТІЛЬКИ тут)
unique:
  - pattern: "[унікальний патерн]"
    description: "[що робить]"
    transferable_to_nanoclaw: true/false
    how: "[як адаптувати]"
```

### Крок 3: Cross-System Comparison Matrix

```markdown
| DIMENSION              | Manus      | Cursor     | Bolt       | Lovable    | Replit     |
|------------------------|------------|------------|------------|------------|------------|
| Identity format        | [тип]      | [тип]      | ...        | ...        | ...        |
| Tool definition        | [тип]      | [тип]      | ...        | ...        | ...        |
| Error handling         | [стратегія]| [стратегія]| ...        | ...        | ...        |
| Output control         | [метод]    | [метод]    | ...        | ...        | ...        |
| Context management     | [метод]    | [метод]    | ...        | ...        | ...        |
| Sub-agent delegation   | [є/нема]   | [є/нема]   | ...        | ...        | ...        |
| Self-verification      | [є/нема]   | [є/нема]   | ...        | ...        | ...        |
| Memory persistence     | [метод]    | [метод]    | ...        | ...        | ...        |
```

### Крок 4: NanoClaw Recommendations

```yaml
recommendations:
  - id: "R01"
    pattern: "[назва]"
    source: "Manus"
    priority: "🔴"
    description: "[що робити]"
    nanoclaw_implementation: "[конкретно як реалізувати через CLAUDE.md / IPC / container]"
    
  - id: "R02"
    pattern: "[назва]"
    source: "Cursor"
    priority: "🟡"
    description: "[що робити]"
    nanoclaw_implementation: "[конкретно як]"
```

### Крок 5: Delta з Claude Prompts (TASK-02)

Порівняй з результатами TASK-02 (Claude system prompts):

```markdown
## Що Non-Claude системи роблять КРАЩЕ за Claude:
1. [патерн] — [хто] — [чому краще]

## Що Claude робить КРАЩЕ за Non-Claude:
1. [патерн] — [чому краще]

## Що ОДНАКОВЕ (universal patterns):
1. [патерн] — [скрізь реалізовано так]

## Що є ТІЛЬКИ у Non-Claude і ПОТРІБНО NanoClaw:
1. [патерн] — [звідки] — [як адаптувати]
```

## OUTPUT
```
analysis/
└── non_claude_prompts_analysis.md
    Секції:
    1. Inventory (крок 1)
    2. Per-System Analysis (крок 2)
    3. Comparison Matrix (крок 3)
    4. NanoClaw Recommendations (крок 4)
    5. Delta з Claude (крок 5)
```

## QUALITY GATES
- [ ] Мінімум 3 з 5 систем проаналізовано (Manus + Cursor обов'язково)
- [ ] Усі 8 вимірів заповнені для кожної системи
- [ ] Comparison Matrix заповнена
- [ ] Recommendations прив'язані до NanoClaw архітектури
- [ ] Delta з TASK-02 чітко показує що НОВОГО дають non-Claude промпти
- [ ] Якщо промпт не знайдено для системи — ЗАФІКСОВАНО (а не пропущено мовчки)
