# MCP Стек для Claude Code

## Ліміт: ≤ 5 серверів одночасно

Правило Shrivu Shankar: "20k+ токенів MCPs = залишається 20k для роботи."
Claude Code's MCP Tool Search автоматично активується якщо tool descriptions > 10% контексту → on-demand завантаження (до 95% економії).

---

## MECE матриця MCP серверів

### Рівень 1 — Базовий стек (починати тут)

| Сервер | Пакет | Для чого | Чому важливий |
|---|---|---|---|
| **Context7** | `@upstash/context7-mcp` | Актуальна документація бібліотек | Усуває hallucinated/deprecated API |
| **Playwright** | `@anthropic-ai/mcp-playwright` | Браузерна автоматизація, UI тести | "Найцінніша agent інтеграція" — спільнота |

### Рівень 2 — Розширений стек (додавай за потребою)

| Сервер | Для чого | Коли додавати |
|---|---|---|
| **GitHub** | PR, issues, репо | Якщо `gh` CLI недостатній |
| **Sentry** | Production помилки | Якщо є Sentry |
| **Notion** | База знань | Якщо команда у Notion |
| **Database (Postgres/Mongo)** | Natural language запити | Analytics-задачі |

### Рівень 3 — Уникати без потреби

- Slack, Gmail, Calendar — важкі для токенів, потрібні рідко
- Будь-що понад 5 серверів — деградація якості

---

## Мінімальна конфігурація .mcp.json

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-playwright"]
    }
  }
}
```

Комітить до репо → вся команда отримує автоматично.

---

## Змінні середовища

```bash
# Обмежити вивід одного MCP (default 25 000)
export MAX_MCP_OUTPUT_TOKENS=10000

# Вимкнути auto tool search (якщо хочеш ручний контроль)
# Не рекомендується для початківців
```

---

## Діагностика проблем MCP

| Симптом | Причина | Рішення |
|---|---|---|
| Повільні відповіді | Забагато MCPs | Видали зайві, залиш ≤ 5 |
| "Context full" рано | MCP output великий | `MAX_MCP_OUTPUT_TOKENS=10000` |
| Claude ігнорує MCP | Tool descriptions конфліктують | Перевір назви інструментів на дублі |
