# Skills та Subagents

## Skills — завантаження експертизи на вимогу

### Принцип прогресивного розкриття

| Рівень завантаження | Що завантажується | Токени |
|---|---|---|
| Завжди | name + description (метадані) | ~100 токенів |
| При активації | SKILL.md тіло | < 5k токенів |
| За потребою | references/* файли | Необмежено |

Порівняно з підходом "все в CLAUDE.md" — economy **40–60% токенів**, повернення ~15 000 токенів на сесію.

### Структура skill

```
.claude/skills/назва-skill/
├── SKILL.md          ← Обов'язковий (YAML frontmatter + інструкції)
├── references/       ← Завантажуються за потребою
└── scripts/          ← Детерміновані скрипти
```

### Мінімальний SKILL.md

```yaml
---
name: code-reviewer
description: >
  Ревʼю коду на якість, безпеку та підтримуваність.
  Активуй при ревʼю PR, аналізі коду, пошуку вразливостей.
allowed-tools: Read, Grep, Glob
---

# Code Review Checklist
1. Організація та структура коду
2. Обробка помилок
3. Продуктивність
4. Вразливості безпеки
```

### Де брати готові skills

- **anthropics/skills** (офіційний репо) — PDF, PowerPoint, тести, арт
- **Trail of Bits** — security skills
- **obra/superpowers** — 20+ battle-tested skills (TDD, debug, collaboration)

---

## Subagents — паралельна робота

### Два підходи (з різними адептами)

**Підхід A — Спеціалізовані агенти** (для повторюваних domain-задач):

```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Ревʼюєр коду. Активуй для перевірки змін перед commit.
model: claude-sonnet-4-6
allowed-tools: Read, Grep
isolation: worktree
---
Ти суворий code reviewer. Перевір код на...
```

**Підхід B — Master-Clone** (Shrivu Shankar, Abnormal AI):
Весь контекст у CLAUDE.md, головний агент сам вирішує коли/як делегувати через вбудований Task(). Shankar: "Custom subagents gatekeep context і нав'язують людські воркфлови — антипатерн."

### Builder-Validator паттерн

Найкраще для quality-critical роботи:

```
Головний агент (Builder) → реалізує
└── Validation subagent (read-only) → верифікує
    └── Результат: builder не знає про валідатора
```

### Cost-оптимізація subagents

- Головна сесія: Opus 4.6
- Subagents: Sonnet 4.6

```bash
export CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-4-6"
```

Економія: **40–50% вартості** агентних задач.

⚠️ Попередження Anthropic: "Opus 4.6 схильний спавнити subagents навіть там де вони не потрібні." Додай до CLAUDE.md явне правило: коли використовувати / не використовувати subagents.

⚠️ Agent teams (координовані Claude instances) споживають **~7× більше токенів** ніж стандартні сесії. Плануй бюджет відповідно.
