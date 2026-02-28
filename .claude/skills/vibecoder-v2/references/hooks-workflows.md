# Hooks та автоматизація

## Що таке hooks

Shell-команди що виконуються автоматично в певні моменти сесії. На відміну від CLAUDE.md (Claude може ігнорувати під тиском контексту) — hooks детерміновані завжди.

Конфігурація: `/hooks` або `~/.claude/settings.json` (глобально) / `.claude/settings.json` (проєкт).

---

## MECE матриця hook-подій

| Hook Event | Коли спрацьовує | Може блокувати? | Найкраще для |
|---|---|---|---|
| `PreToolUse` | До виклику інструменту | ✅ Так | Захист файлів, валідація |
| `PostToolUse` | Після виклику | ❌ Ні | Форматування, логування |
| `Notification` | Claude потребує уваги | ❌ Ні | Desktop алерти |
| `Stop` | Claude завершив відповідь | ❌ Ні | Нагадування, чеклісти |
| `UserPromptSubmit` | Користувач відправив запит | ✅ Так | Ін'єкція skill-контексту |

---

## Три найважливіші хуки для початківця

### 1. Авто-форматування (PostToolUse)

Форматує TypeScript після кожного редагування:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "jq -r '.tool_input.file_path' | { read f; [[ $f == *.ts ]] && npx prettier --write \"$f\" 2>/dev/null; true; }"
      }]
    }]
  }
}
```

⚠️ Увага: автофомрат на кожен edit може спожити 160k токенів за 3 раунди. Для cost-sensitive проєктів — запускати між сесіями.

### 2. Захист критичних файлів (PreToolUse)

Блокує зміну .env та package-lock:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "file=$(jq -r '.tool_input.file_path'); if [[ \"$file\" == *\".env\"* || \"$file\" == *\"package-lock\"* ]]; then echo 'BLOCKED: protected file'; exit 1; fi"
      }]
    }]
  }
}
```

### 3. Desktop-нотифікація (Notification)

Коли Claude чекає — повідомлення на macOS:

```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"Claude Code потребує уваги\" with title \"Claude Code\"'"
      }]
    }]
  }
}
```

---

## Правило дизайну хуків (критичне)

**НЕ блокуй під час запису файлу** — це плутає агента в середині плану.

✅ Правильно: block-at-submit (PreToolUse на `Bash(git commit*)`) — перевір тест-файл перед commit.

❌ Неправильно: блокувати Edit коли Claude в середині виконання плану.

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash(git commit*)",
      "hooks": [{
        "type": "command", 
        "command": "test -f .tests-passed || { echo 'Тести не пройшли — commit заблокований'; exit 1; }"
      }]
    }]
  }
}
```

---

## Slash-команди (простіша альтернатива)

Зберігай шаблони промптів у `.claude/commands/<назва>.md`:

```markdown
# .claude/commands/fix-github-issue.md
Проаналізуй та виправ GitHub issue: $ARGUMENTS.
1. `gh issue view $ARGUMENTS` — деталі
2. Знайди релевантні файли
3. Реалізуй зміни
4. Напиши та запусти тести
5. Створи описовий commit і PR
```

Виклик: `/project:fix-github-issue 123`

Комітти .claude/commands/ до репо — вся команда отримує автоматично.
