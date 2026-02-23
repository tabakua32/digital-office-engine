---
name: diary
description: Record session diary entry at end of work session
---
# Session Diary

## When to Use
- End of every work session
- Triggered automatically by PreCompact hook
- Manually via /diary command

## What to Record
Save to groups/{agent}/memory/diary/{YYYY-MM-DD-HH}.md:

```markdown
# Diary: {date} {time}

## Tasks Completed
- {task 1}: {result}
- {task 2}: {result}

## Decisions Made
- {decision}: {reasoning}

## What Worked
- {insight}

## What Didn't Work
- {problem}: {lesson}

## Pending
- {next step 1}
- {next step 2}
```

## Also
Insert summary into SQLite memory table:
```sql
INSERT INTO memory (agent_id, layer, category, content, importance, source)
VALUES ('{agent}', 'L3', 'diary', '{summary}', 5, 'auto');
```

## Frequency
- Every session end (mandatory)
- After major milestones (optional)
