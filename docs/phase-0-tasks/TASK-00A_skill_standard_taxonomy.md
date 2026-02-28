# TASK-00A: Skill Standard + Taxonomy Matrix

## МЕТА
Визначити ЩО ТАКЕ NanoClaw skill і ЯКІ ТИПИ існують.
Це фундамент. Без нього все подальше — хаос.

## КОНТЕКСТ
NanoClaw OS — операційна система для AI marketing department.
Кожен skill мусить працювати через: NanoClaw (containers), Claude Code (CLI),
Claude.ai (browser), Cowork (desktop). Тому стандарт базується на Anthropic-native форматах.

## INPUT (прочитай ПОВНІСТЮ кожен файл)

### Anthropic стандарти (у repos):
```
# Claude Code skill format — ЕТАЛОН:
[шлях до claude-code-main або claude-code-skills-main]/
  └── .claude/skills/[name]/SKILL.md    ← офіційний формат

# Anthropic Cookbook:
[шлях до claude-cookbooks-main]/        ← офіційні рецепти

# Claude Agent SDK:
[шлях до claude-agent-sdk-typescript-main]/  ← API контракти

# Офіційні plugins:
[шляхи до claude-plugins-official, knowledge-work-plugins, financial-services-plugins]/
```

### Наші артефакти:
```
skill-architect/SKILL.md + references/   ← наявний стандарт (АПГРЕЙДИМО)
prompt-enhancer/SKILL.md + references/   ← вразливості + task types
YAKOMANDA_Agent_Prompt_System_v1.md      ← 52 блоки, Decision Matrix
Marketing_Chain_v3_2026.md               ← 14 ланок
NanoClaw_architecture.md                 ← runtime constraints
MECE_Marketing_Matrix_v5.xlsx            ← поточні позиції
```

### Кастомні skill architects (у repos):
```
[шляхи до claude-code-skill-factory-dev, awesome-claude-skills-master,
 та інших repos з "skill" у назві які містять meta-рівень створення скілів]
```

### Завершені дослідження:
```
claude_prompts_analysis.md               ← TASK-02 результат
[інші завершені аналізи якщо є]
```

## ЗАДАЧА

### Крок 1: Audit існуючих стандартів (1 год)

Прочитай ВСІ джерела вище і для кожного витягни:

```yaml
source: "[назва]"
type: "anthropic_official | our_system | community"
skill_format:
  file_structure: "[як організовані файли]"
  required_sections: ["список обов'язкових секцій"]
  optional_sections: ["список опціональних"]
  naming: "[конвенції іменування]"
  size_limits: "[рекомендації по розміру]"
output_format:
  how_defined: "[як задається формат виходу]"
  templates: "[чи є шаблони]"
quality:
  how_checked: "[як перевіряється якість]"
compatibility:
  claude_code: true/false
  claude_ai: true/false
  nanoclaw: true/false
  cowork: true/false
unique: "[що є тут і ніде більше]"
```

### Крок 2: Unified Skill Standard (1.5 год)

Синтезуй з усіх джерел ОДИН стандарт. Пріоритет:
1. Anthropic офіційний формат (100% сумісність)
2. Наші розширення (ЯКОМАНДА, vulnerability shields)
3. Community best practices (якщо не суперечать 1 і 2)

```markdown
# skill_standard.md

## File Structure

[назва-скіла]/
├── SKILL.md                    ← Головний файл (<500 рядків)
│                                  Sandwich: critical first 20% + last 10%
│
├── references/                 ← Деталі (progressive disclosure)
│   ├── [topic].md              Claude Code / NanoClaw читає за потреби
│   └── ...
│
├── scripts/                    ← Автоматизація (якщо потрібна)
│   └── [script].py|sh
│
├── assets/                     ← Статичні ресурси
│   └── [templates, examples]
│
└── CLAUDE.md                   ← NanoClaw-specific: persistent memory template
                                   (опціонально, тільки для NanoClaw runtime)

## SKILL.md Required Sections

### Header Block (перші 5%)
- Назва, версія, автор
- Тип: agent | skill | connector | command | module | process
- Домен: marketing | dev-ops | visual | data | communication | meta
- Task type: analytical | generative | transformational | orchestration
- Compatibility: nanoclaw | claude-code | claude-ai | cowork

### Quick Reference (наступні 15%)
- Routing table: "якщо задача X → зроби Y"
- Input/Output contract summary
- Dependencies (які context modules потрібні)

### Core Logic (середні 60%)
- Identity + Boundaries
- Process steps
- Quality gates
- Error handling

### Output Template (наступні 10%)
- Формат виходу
- Self-check rubric

### Critical Rules (останні 10%)
- Повторення найважливіших правил
- Anti-patterns
- Safety boundaries

## Quality Criteria
[конкретні критерії з scoring rubric]

## Anthropic Compatibility Matrix
[як конвертувати для кожного runtime]
```

### Крок 3: Taxonomy Matrix (1.5 год)

Створи MECE матрицю домен × функція:

```markdown
# skill_taxonomy.md

## Domains (MECE по предметній області)

### marketing/
Chain links: ①-⑫
Sub-domains:
  ├── market-intelligence/    (①)
  ├── customer-analysis/      (②)
  ├── pmf-validation/         (⓪)
  ├── positioning/            (③)
  ├── offer/                  (④)
  ├── brand/                  (④.5)
  ├── content/                (⑤)
  ├── geo-aeo/                (⑤.5)
  ├── distribution/           (⑥)
  ├── conversion/             (⑦)
  ├── customer-experience/    (⑧)
  ├── retention/              (⑨)
  ├── analytics/              (⑩)
  ├── scaling/                (⑪)
  └── feedback/               (⑫)

### dev-ops/
Sub-domains:
  ├── debugging/
  ├── testing/
  ├── security/
  ├── deployment/
  └── monitoring/

### visual/
Sub-domains:
  ├── graphic-design/
  ├── ui-ux/
  ├── video/
  ├── infographic/
  └── brand-identity/

### data/
Sub-domains:
  ├── analytics/
  ├── reporting/
  ├── etl/
  └── visualization/

### communication/
Sub-domains:
  ├── email/
  ├── social-media/
  ├── pr/
  ├── messenger/
  └── community/

### meta/
Sub-domains:
  ├── factory/
  ├── audit/
  ├── orchestration/
  └── routing/

## Functions (MECE по типу дії)

### agent
Autonomy: HIGH
Description: Приймає рішення, планує, делегує
YAKОМANDA blocks: FULL SET (I1-E51)
Model tier: Opus (complex) | Sonnet (standard)
Example: VP Marketing Orchestrator

### skill
Autonomy: MEDIUM
Description: Виконує конкретну задачу за запитом
YAKОМANDA blocks: I1-I4, P2, P14, P29, V41
Model tier: Sonnet (standard) | Haiku (simple)
Example: SEO Audit Skill

### connector
Autonomy: LOW (bridge)
Description: MCP інтеграція із зовнішньою системою
YAKОМANDA blocks: I1, P2 (мінімум)
Model tier: N/A (MCP server)
Example: Google Ads Connector

### command
Autonomy: LOW (atomic)
Description: Slash-команда, одна швидка дія
YAKОМANDA blocks: I1, P2 (мінімум)
Model tier: Haiku (speed)
Example: /brief — генерує creative brief

### module
Autonomy: NONE (data)
Description: Контекстний блок, живить інших агентів
YAKОМANDA blocks: N/A
Model tier: N/A
Example: ICP Module (audience/icp.md)

### process
Autonomy: ORCHESTRATED
Description: Multi-step workflow, координує інших
YAKОМANDA blocks: I1-I4, P2, P19, P26 (handoff-focused)
Model tier: Sonnet (orchestration)
Example: Campaign Launch Process

## Matrix Population

Для КОЖНОЇ заповненої клітинки матриці:
| Domain/Sub | Function | Name | Task Type | Chain Link | Model | Bias Set | Context Deps |
|------------|----------|------|-----------|------------|-------|----------|--------------|
| ... | ... | ... | ... | ... | ... | ... | ... |

УВАГА: не заповнюй ВСЮ матрицю зараз. Заповни:
- marketing/ × agent (усі)
- marketing/ × skill (усі)
- dev-ops/ × agent (core)
- dev-ops/ × command (core)
- meta/ × agent (усі)
Решту заповнимо після ФАЗИ 1 (аналіз repos покаже що ще потрібно).
```

## OUTPUT
```
foundation/
├── standards_audit.md          ← Крок 1: аудит існуючих стандартів
├── skill_standard.md           ← Крок 2: unified standard
└── skill_taxonomy.md           ← Крок 3: MECE матриця
```

## QUALITY GATES
- [ ] Усі Anthropic джерела прочитані (cookbook, SDK, plugins, Claude Code format)
- [ ] Усі наші артефакти враховані (ЯКОМАНДА, Chain, NanoClaw)
- [ ] Кастомні skill architects з repos проаналізовані
- [ ] skill_standard.md сумісний з УСІМА 4 runtime (NanoClaw, CC, Claude.ai, Cowork)
- [ ] Taxonomy — MECE (no overlaps, no gaps) по обох осях
- [ ] Кожна функція має визначені ЯКОМАНДА blocks
- [ ] Кожна функція має визначений model tier
- [ ] Матриця заповнена для marketing + dev-ops + meta (core)
