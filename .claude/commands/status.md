---
description: Show system status — departments, memory, pending tasks
---

Check the digital office system status:

1. Read shared/knowledge-base/cross-agent-context.md for department list
2. Run health check: `bash shared/scripts/health-check.sh`
3. Check each active department:
   - Read groups/{dept}/workspace/pipeline-state.md for active pipelines
   - Count diary entries in groups/{dept}/memory/diary/
   - Check Airtable for pending tasks (Status = "To Do")
4. Report summary in structured format

Output format:
```
## System Status — {date}
| Department | Pipeline | Diary Entries | Pending Tasks |
|-----------|----------|---------------|---------------|
| marketing | {state}  | {count}       | {count}       |

### Health
- Engine: {running/stopped}
- DB: {ok/error} ({N} memory entries)
- Last backup: {date}
- Git: {last commit}
```
