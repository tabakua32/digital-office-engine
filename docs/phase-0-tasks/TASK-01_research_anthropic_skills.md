# TASK-01: Дослідження Anthropic Official Skills

## МЕТА
Екстрагувати FORMAT PATTERNS з офіційних Anthropic skills.
Це патерни від ТВОРЦІВ платформи — еталон як будувати skills для Claude.

## КОНТЕКСТ
Ми будуємо Skill Factory для генерації 77 маркетингових AI-агентів.
Писатимемо ВСЕ з нуля, але формат і структуру беремо з найкращих джерел.
Anthropic skills — джерело #1 для формату.

## INPUT FILES (завантаж ці репо перед стартом)
```
git clone https://github.com/anthropics/claude-plugins-official.git
git clone https://github.com/anthropics/knowledge-work-plugins.git
git clone https://github.com/anthropics/financial-services-plugins.git
```

## ЗАДАЧА

### Крок 1: Інвентаризація
Знайди ВСІ файли SKILL.md у трьох репо.
Для кожного запиши: шлях, назва, домен, розмір (рядки).

### Крок 2: Структурний аналіз КОЖНОГО SKILL.md
Для кожного скіла витягни:

```
SKILL: [назва]
DOMAIN: [marketing | financial | knowledge-work | інше]
LINES: [кількість рядків]
TASK_TYPE: [analytical | generative | transformational | orchestration]

STRUCTURE (секції у порядку появи):
1. [назва секції] — [1 речення що містить]
2. ...

OUTPUT_FORMAT: [як задається формат виходу — template? schema? приклад?]
QUALITY_GATES: [як перевіряється якість — чеклист? self-check? rubric?]
ERROR_HANDLING: [що робити при помилці — fallback? escalation? retry?]
TOOLS_USED: [які інструменти використовує — bash? web? file creation?]
REFERENCES_DIR: [чи є references/ папка, що в ній]
SCRIPTS_DIR: [чи є scripts/ папка, що в ній]
```

### Крок 3: Cross-Skill Pattern Extraction
Знайди ПОВТОРЮВАНІ патерни (зустрічаються у 3+ скілах):

```
PATTERN: [назва патерну]
FREQUENCY: [у скількох скілах зустрічається]
WHERE: [список скілів]
EXAMPLE: [конкретний приклад коду/тексту з одного скіла]
WHY_IT_WORKS: [чому цей патерн ефективний — 1-2 речення]
```

Мінімум 15 патернів.

### Крок 4: Unique Patterns
Для кожного ДОМЕНУ (marketing, financial, knowledge-work) —
що є ТІЛЬКИ у цьому домені і ніде більше?

```
DOMAIN: [домен]
UNIQUE_PATTERNS:
- [патерн]: [чому унікальний] — [чи потрібен для маркетингових агентів?]
```

### Крок 5: Anti-Patterns
Що виглядає як ПОМИЛКА або СЛАБКІСТЬ у проаналізованих скілах?
(абстрактні інструкції замість конкретних, відсутність error handling, тощо)

```
ANTI_PATTERN: [опис]
WHERE: [в яких скілах]
IMPACT: [як це вплине на якість агента]
```

## OUTPUT
Один файл: `anthropic_skills_analysis.md`
Структура:
1. Inventory Table (крок 1)
2. Per-Skill Analysis (крок 2)
3. Cross-Skill Patterns (крок 3) — ЦЕ НАЙВАЖЛИВІША СЕКЦІЯ
4. Domain-Unique Patterns (крок 4)
5. Anti-Patterns (крок 5)
6. Summary: Top-10 Takeaways for Skill Factory

## QUALITY GATES
- [ ] Кожен SKILL.md прочитаний повністю (не скорочено)
- [ ] Мінімум 15 cross-skill patterns знайдено
- [ ] Кожен pattern має КОНКРЕТНИЙ приклад коду/тексту
- [ ] Anti-patterns секція не порожня
- [ ] Summary містить actionable takeaways, не загальні фрази
