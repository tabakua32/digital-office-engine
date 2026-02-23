---
description: Write a session diary entry for the current department
---

Write a diary entry following the diary skill protocol:

1. Read .claude/skills/system/diary/SKILL.md for format
2. Determine current department from context
3. Create file: groups/{dept}/memory/diary/{YYYY-MM-DD-HH}.md
4. Include:
   - Tasks completed this session
   - Decisions made and reasoning
   - What worked / what didn't
   - Pending items for next session
5. Also insert summary into SQLite: shared/data/office.db (memory table, layer='L3')
