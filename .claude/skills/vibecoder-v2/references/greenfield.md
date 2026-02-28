# Greenfield Bootstrap — з нуля до проєкту

<!-- PRIMACY: послідовність критична — не міняй порядок -->

## Правильна послідовність (порушення порядку = butterfly effect)

```
1. git init + ручний CLAUDE.md
2. ~/.claude/settings.json (deny-rules)
3. Plan Mode → spec-interview
4. Реалізація першого milestone
5. git commit
6. /init (збагачення CLAUDE.md)
```

Анти-паттерн — запустити Claude Code без CLAUDE.md і почати кодувати → Claude неправильно розуміє ранні припущення → будує весь проєкт на хибних основах.

---

## Крок 1 — Що створити вручну ДО першого запуску Claude

```bash
mkdir my-project
cd my-project
git init
```

Потім вручну напиши CLAUDE.md (не через `/init` — він для збагачення, не для старту):

```markdown
# [Назва проєкту]

## About
[1-2 речення: що робить і навіщо]

## Tech Stack
Language: [...] | Framework: [...] | Package manager: [...]

## Commands
- Dev: `npm run dev`
- Test: `npm test`
- Typecheck: `npm run typecheck`

## Workflow Rules
- Use Plan Mode for any non-trivial task
- Run typecheck after every code change
- Commit after each completed sub-task
- Never guess API signatures — read source files first
- If stuck 2+ times: stop, list failures, propose 3 alternatives

## Code Standards
- [Твої стандарти]

## Error Prevention
[Додавай правила після кожного виправлення]
```

> Конфлікт джерел: HumanLayer не рекомендує `/init` для генерації CLAUDE.md ("найвища точка впливу — не auto-generate"). Sid Bharath рекомендує "/init на кожному новому проєкті". Узгодження: пиши CLAUDE.md вручну спочатку; `/init` лише для збагачення після першого коду.

Ліміт — 150 рядків. Frontier LLMs надійно дотримуються ~150–200 інструкцій; Claude Code system prompt займає ~50, залишається ~100–150 для CLAUDE.md.

---

## Крок 2 — Безпека перед кодом

Мінімальний `~/.claude/settings.json` (якщо ще немає):
```json
{
  "permissions": {
    "deny": ["Bash(rm *)", "Bash(rm -rf *)", "Bash(sudo *)", "Read(**/.env*)"]
  }
}
```

Повний конфіг → [security.md](security.md).

---

## Крок 3 — Перша сесія: Plan Mode + spec-interview

```bash
claude
```

Одразу: `Shift+Tab` двічі → Plan Mode.

**Перший prompt шаблон:**
```
Я починаю новий проєкт з нуля в порожній директорії.

ПРОЄКТ: [1-2 абзаци опису]

ОБМЕЖЕННЯ:
- Tech stack: [твої preferencs]
- Має бути: [ключові нефункціональні вимоги]
- Цільові юзери: [хто це]

Перш ніж планувати — задай мені 5-10 уточнюючих питань про
вимоги, архітектуру та UX. Задавай неочевидні питання —
копай edge cases та tradeoffs.

Після того як ми домовимось, створи spec.md з:
1. Вимоги
2. Tech stack рішення з обґрунтуванням
3. Огляд архітектури
4. 3 milestone реалізації
5. Детальний TODO для milestone 1
```

VelvetShark задокументував: Claude задав 32 питання для bookmark manager перед тим як почати. Це нормально і правильно.

---

## Крок 4 — Після першої сесії

```bash
git add -A && git commit -m "feat: initial implementation milestone 1"
```

Потім — збагачення CLAUDE.md:
```
/init
```

Claude прочитає існуючий код та запропонує доповнення до CLAUDE.md. Переглянь та прийми/відхили кожне.

---

## Крок 5 — Перше виправлення → перше правило

Як тільки ти виправив щось що Claude зробив неправильно:
```
# [натисни # прямо в терміналі]
Правило: [що не треба робити і що робити натомість]
```

Або:
```
Оновити CLAUDE.md щоб ця помилка не повторилась.
```

Це запускає "правило компаундингу" — CLAUDE.md росте разом з проєктом.

---

## Еталонна структура після першої сесії

```
my-project/
├── CLAUDE.md              ← ≤150 рядків, committed
├── spec.md                ← з spec-interview, committed
├── .mcp.json              ← Context7 + Playwright мінімум
├── .gitignore             ← .env, node_modules, etc.
└── .claude/
    ├── settings.json      ← deny-rules, committed
    └── commands/
        └── interview.md   ← spec-interview slash-команда
```

---

<!-- RECENCY: повторення критичного -->

## Checklist старту (copy-paste)

- [ ] `git init` + ручний CLAUDE.md ≤150 рядків
- [ ] `~/.claude/settings.json` з deny для `rm *` та `.env*`
- [ ] `Shift+Tab` двічі → Plan Mode при першому запуску
- [ ] spec-interview перед будь-яким кодом
- [ ] Перший commit після першої робочої реалізації
- [ ] `/init` для збагачення CLAUDE.md (після коду, не перед)
- [ ] Після першого виправлення: `#` → додай правило в CLAUDE.md

## Антипаттерни (задокументовані провали)
- Запускати Claude без CLAUDE.md → неправильні ранні припущення
- Починати з `/init` → auto-generated CLAUDE.md пропускає критичні деталі
- Пропускати spec-interview → butterfly effect при переймі вимог
- Не робити commit до кінця → немає точок відновлення
