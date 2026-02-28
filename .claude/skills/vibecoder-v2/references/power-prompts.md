# Power Prompts та Meta-Prompting

<!-- PRIMACY: найвищий ROI — перші -->

## Три power prompts Бориса Черни (автор Claude Code)

Верифіковані джерело: Threads-тред Бориса, січень 2026. Використовує щодня.
Ефект: "2–3× якість фінального результату."

### А — "Prove to me this works"
```
Prove to me this works. Diff the behavior between main and this feature branch.
```
Коли: після реалізації, перед PR. Claude демонструє коректність через behavioral diff замість assertions.

### Б — "Grill me on these changes"
```
Grill me on these changes and don't make a PR until I pass your test.
```
Коли: Claude стає reviewer, ти маєш довести розуміння. Потужно для незнайомих кодових баз.

### В — "Elegant solution" після посереднього першого pass
```
Knowing everything you know now, scrap this and implement the elegant solution.
```
Коли: є робоча, але посередня реалізація. Використовує весь контекст накопиченого першого спроби.

---

## Spec-Interview Pattern (Thariq Shihipar, Anthropic)

Тред з 1.3M переглядів та 10 000+ закладок.

**Двосесійний воркфлов:**
- Сесія 1: Claude інтерв'ює тебе → пише spec
- Сесія 2 (чистий контекст): реалізує spec

Ключовий інсайт: розділення інтерв'ю та реалізації запобігає перенесенню bias.

### Slash-команда (зберегти як `.claude/commands/interview.md`)

```markdown
---
description: Інтерв'ювати мене для розширення spec
argument-hint: [spec-file]
allowed-tools: AskUserQuestion, Read, Glob, Grep, Write, Edit
model: opus
---

Прочитай поточний spec та інтерв'юй мене щоб зробити його готовим до реалізації.

Поточний spec: @$ARGUMENTS

Правила:
- Використовуй інструмент AskUserQuestion виключно для питань
- Задавай неочевидні питання про реалізацію, UX, edge cases, tradeoffs
- Будь дуже детальним — продовжуй до повного spec
- Перед записом: підсумуй фінальний outline та попроси підтвердження
- Потім перезапиши $ARGUMENTS структурованим spec
```

Використання: `/interview SPEC.md` → (clear) → `Implement @SPEC.md`

---

## Анатомія 10× промпту (Dzombak + Anthropic)

**Три якості (не "стислість" — деталі що скеровують Claude допомагають):**
- **Clear** — опишіть намір та проблему, не тільки симптом
- **Explicit** — включіть всі важливі деталі
- **Specific** — вкажіть scope та напрямок

### Before / After (реальні приклади з вимірюваною різницею)

| 2× промпт | 10× промпт |
|---|---|
| "Друкування у пошуковому полі тормозить. Знайди та виправ баг." | "Друкування, скролінг та вибір результатів тормозять при сотнях результатів. Знайди все що блокує main thread під час цих взаємодій. Все таке має бути async." |
| "Додай тести для foo.py" | "Напиши тест для foo.py що покриває edge case коли юзер залогінений. Уникай mocks." |
| "Додай calendar widget" | "Подивись як існуючі widgets працюють на home page. HotDogWidget.php — хороший приклад. Слідуй патерну для calendar widget що дозволяє вибирати місяць та пагінувати вперед/назад." |

### Формула 10× промпту

```
[CONTEXT: @file посилання на 2-4 релевантні файли]
[GOAL: що будуємо і ЧОМУ важливо — 1-2 речення]
[APPROACH: напрямок рішення, не симптоми]
[CONSTRAINTS: MUST/MUST NOT правила з альтернативами]
[VERIFICATION: як підтвердити успіх — тести, builds, diffs]
[THINKING: "think hard" для складних рішень]
```

### Constraints vs Goals — правильний фрейминг

Завжди давай альтернативу поряд із забороною:
```markdown
❌ "Never use --foo-bar"
✅ "Never use --foo-bar; prefer --baz instead"
```

```markdown
## Goal
Побудувати endpoint реєстрації юзера що валідує унікальність email
та відправляє verification email. Критично бо мали дублікати в production.

## Constraints
- MUST використовувати існуючий EmailService (src/services/email.ts)
- MUST NOT зберігати паролі plaintext — bcrypt з 12 rounds
- MUST повертати 409 Conflict для дублікатів, не generic 500
- Never use `any` type; prefer proper TypeScript interfaces instead

## Verification
- Тести для: валідна реєстрація, дублікат email, невалідний формат
- Run `npm run test:unit`
```

---

## Thinking-модифікатори — оновлений статус

Симон Вілліcон деobfuscated JS Claude Code і знайшов hard-coded бюджети:
- `think` → 4 000 токенів
- `think hard` / `megathink` → 10 000 токенів
- `ultrathink` → 31 999 токенів

Статус v2.1.11+ (січень 2026): thinking вбудований за замовчуванням на максимальному бюджеті. Ключові слова deprecated але функціональні на старих версіях.

Важливо: це клієнтська фіча Claude Code. Не працює в claude.ai або API-дзвінках.

```
Коли → thinking level:
Стандартний код → (нічого, default достатньо)
Архітектурні рішення → "think hard"
Складні баги → "think harder"
Критичні/незворотні рішення → "ultrathink"
```

---

## Dekompozиція задач: один великий vs кілька малих

Правило Anthropic: якщо задача має 3+ відмінні кроки → декомпозуй.

**Стратегія fan-out** для великих міграцій:
```bash
claude -p "Мігруй foo.py з React на Vue. Поверни OK або FAIL." < foo.py
```

**Послідовність Explore → Plan → Code → Commit** для нетривіальних задач:
```
"Прочитай @src/auth/ — не пиши код."
→ "think hard: як реалізувати X. Розглянь 2-3 підходи."
→ "Реалізуй підхід #2. Після кожного файлу запускай typecheck."
→ "Commit з описовим повідомленням. Оновити документацію."
```

---

<!-- RECENCY: повторення -->

## Швидка довідка

```
Верифікація → "Prove to me this works"
Review → "Grill me on these changes"
Рефакторинг → "Scrap this, implement elegant solution"
Новий проєкт → /interview SPEC.md → (clear) → Implement @SPEC.md
Складне рішення → "think hard: [питання]"
Формула → Context + Goal + Approach + Constraints + Verification
```
