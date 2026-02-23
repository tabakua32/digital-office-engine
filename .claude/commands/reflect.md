---
description: Analyze recent diary entries and update learnings + CLAUDE.md
---

Run the reflect skill protocol:

1. Read .claude/skills/system/reflect/SKILL.md for full process
2. Read all diary entries from groups/{dept}/memory/diary/ (last 7 days)
3. Read current groups/{dept}/memory/learnings.md
4. Read current groups/{dept}/CLAUDE.md
5. Identify patterns (what consistently works or fails)
6. Update learnings.md with new insights
7. If a learning appears 3+ times → propose CLAUDE.md rule update
8. Archive diary entries older than 30 days to SQLite
9. Show all proposed changes before applying
