# Безпека та дозволи

<!-- PRIMACY: критичні ризики — перші -->

## Задокументовані кейси знищення даних

Це не теоретичні ризики. Всі з офіційного GitHub репозиторію Anthropic (Tier 1):

| Issue | Що сталось | Наслідки |
|---|---|---|
| #10077 | `rm -rf` від root на Ubuntu/WSL2 | Всі файли користувача знищено |
| #12637 | Claude створив літеральну `~` директорію; пізніше `rm -rf *` → home | Home directory знищено |
| #24196 | Claude додав `rm -rf` "для cleanup", piped stderr → `/dev/null` | ~1–1.5 тижні роботи |
| #3109 | Видалив TV-файли, потім **вигадав пояснення** | Дані + довіра |
| #7787 | Самостійно видалив spec-файл (єдину копію) | Специфікація втрачена |

Додаткові Tier 2-3: Reddit LovesWorkin — home directory wipe (197 HN points); Nick Davydov — 15 років сімейних фото знищено Claude Cowork.

**Паттерн:** Claude додає cleanup-команди яких юзер не очікує, іноді ховаючи помилки redirect'ом stderr.

---

## Безпечний settings.json для початківців

Файл: `~/.claude/settings.json` (глобальний) або `.claude/settings.json` (проєктний).

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)", "Bash(npm test *)", "Bash(bun run *)",
      "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)",
      "Bash(git add *)", "Bash(git commit *)", "Bash(git branch *)",
      "Bash(ls *)", "Bash(cat *)", "Bash(grep *)", "Bash(rg *)",
      "Bash(find *)", "Bash(head *)", "Bash(tail *)",
      "Bash(echo *)", "Bash(mkdir *)", "Bash(pwd *)", "Bash(wc *)"
    ],
    "deny": [
      "Bash(rm *)", "Bash(rm -rf *)", "Bash(sudo *)",
      "Bash(git push --force *)", "Bash(git reset --hard *)",
      "Bash(curl *)", "Bash(wget *)", "Bash(nc *)",
      "Read(**/.env*)", "Read(**/secrets/**)",
      "Read(**/*.pem)", "Read(**/*.key)",
      "Read(**/.ssh/**)", "Read(**/.aws/**)"
    ]
  }
}
```

**Синтаксичні правила (критично):**
- `Bash(ls *)` зі пробілом → дозволяє `ls -la`, але НЕ `lsof`
- Без пробілу `Bash(ls*)` → дозволяє обидва
- `Read` або `Edit` без дужок → дозволяє ВСІ файли
- Deny завжди має пріоритет над allow
- Shell оператори (`&&`, `||`, `;`, `|`) розбивають wildcard matching → потребують явного дозволу

---

## Захист .env (multi-layer)

> ⚠️ Conflict flag: `.claudeignore` НЕ блокує надійно .env. The Register незалежно відтворив це (28 січня 2026). GitHub Issues #8031, #4160 підтверджують. Claude може бачити .env через system-reminder навіть з deny-rules.

**Єдиний надійний захист — виносити секрети за межі директорії проєкту.**

```
Шар 1: Deny rules у settings.json (вище — "Read(**/.env*)")
Шар 2: Перемісти секрети ПОЗА директорію проєкту (найефективніше)
Шар 3: Vault references замість plaintext: op://Work/Stripe/secret-key
Шар 4: Unix дозволи: chmod 600 .env
Шар 5: Container isolation для максимальної безпеки
```

---

## dangerouslySkipPermissions

Прапор `-d` або `--dangerously-skip-permissions` вимикає ВСІ permission prompts.

Безпечно тільки одночасно виконавши всі умови:
- Запускаєш в ізольованому контейнері / VM
- Немає доступу до production credentials
- Директорія проєкту — одноразова або повністю в git
- Розумієш що Claude може виконати будь-яку команду

Ніколи не використовуй `-d` в production середовищі або з реальними credentials.

---

## Sandbox setup

Anthropic's sandbox — OS-level ізоляція (не application-level).
- macOS: Apple Seatbelt — вбудований за замовчуванням
- Linux: bubblewrap + socat

**Linux/WSL2 setup:**
```bash
sudo apt install bubblewrap socat -y
# Всередині Claude Code:
/sandbox
# Вибери "Auto-allow mode"
# Перевірка: claude --diagnostic → "Sandbox: enabled (bubblewrap)"
```

Внутрішнє тестування Anthropic: **84% зниження кількості permission prompts** у sandbox-режимі.

---

## Три CVE (лютий 2026)

| CVE | CVSS | Опис | Виправлено |
|---|---|---|---|
| CVE-2025-59536 | 8.7 | Code injection через `.mcp.json` у клонованих репо | v1.0.111 |
| CVE-2026-21852 | 5.3 | API key exfiltration через `ANTHROPIC_BASE_URL` | v2.0.65 |
| — | — | Prompt injection через `.docx` файли (PromptArmor) | Патч є |

**Дія:** перевір версію `claude --version`. Оновися якщо нижче патч-версій вище.

---

<!-- RECENCY: повторення критичного -->

## Швидка довідка

```
rm -rf → deny-rules → обов'язково
.env → виноси за межі проєкту → .claudeignore ненадійний
Sandbox → /sandbox → 84% менше prompts
dangerouslySkipPermissions → тільки в ізольованому контейнері
CVE → claude --version → оновись до v2.0.65+
```

## Мінімальний checklist безпеки для нового проєкту
- [ ] `~/.claude/settings.json` з deny для `rm *`, `sudo *`, `.env*`
- [ ] `.env` поза директорією проєкту або vault references
- [ ] `/sandbox` якщо є ризиковані операції
- [ ] `claude --version` ≥ 2.0.65
- [ ] git init → перший commit → далі працюй
