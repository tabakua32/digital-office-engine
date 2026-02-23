# Airtable Integration Reference

## Base: Маркетингова Воронка
Base ID: appBuGJoQjZ627Kr7

## Tables

### Office Tasks (tblyUKmiXVnZLdC0v) — NEW
Task management for all departments.
| Field | Type | Values |
|-------|------|--------|
| Task Name | singleLineText | Task title |
| Department | singleSelect | marketing, code, research, content, personal, system |
| Status | singleSelect | To Do, In Progress, Done, Blocked |
| Priority | singleSelect | High, Medium, Low |
| Assigned To | singleSelect | coordinator, copywriter, designer, analyst |
| Description | multilineText | Full task description |
| Output | multilineText | Result (filled by agent) |
| Due Date | date | ISO format |
| Pipeline Skill | singleLineText | Skill name for multi-step tasks |

### Контент-календар (tblxvAmOivi3qbxBn) — EXISTING
Content calendar for marketing.
| Field | Type |
|-------|------|
| Назва контенту | singleLineText |
| Тип контенту | singleSelect |
| Дата публікації | date |
| Час публікації | singleLineText |
| Статус | singleSelect |
| Відповідальний | singleSelect |
| Опис/Сценарій | multilineText |
| Хештеги | multilineText |
| CTA | singleLineText |
| Посилання на матеріали | url |
| Пріоритет | singleSelect |

### Other Existing Tables
- Ліди (tblWwNI0JExQeygZS) — Lead management
- KPI та метрики (tblcVv9UsrqrV0c3j) — Metrics tracking
- Бюджет кампанії (tbldT7XowW8w7FVv8) — Budget
- Канали просування (tblhwXyuTSmFMbBeL) — Promotion channels

## Agent Workflow
1. At session start → check Office Tasks where Status = "To Do"
2. Pick highest priority task for the department
3. Set Status = "In Progress"
4. Execute task (using Pipeline Skill if specified)
5. Write result to Output field
6. Set Status = "Done"
