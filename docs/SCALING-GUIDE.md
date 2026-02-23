# How to Add a New Department

## Time: ~15 minutes

### Step 1: Create Structure (2 min)
```bash
cp -r .claude/skills/_templates/DEPARTMENT-TEMPLATE/ groups/{new-dept}/
```

### Step 2: Customize CLAUDE.md (5 min)
Edit `groups/{new-dept}/CLAUDE.md`:
- Identity (who is this agent)
- Team (subagents)
- 7 rules maximum

### Step 3: Create Telegram Bot (3 min)
1. @BotFather → /newbot → get token
2. Add token to .env: `TELEGRAM_BOT_TOKEN_{DEPT}=...`

### Step 4: Register in NanoClaw (2 min)
Add group mapping. Send `/chatid` in the bot to get the chat ID.
Register via IPC or direct SQLite insert.

### Step 5: Test (3 min)
Send a test message → verify response.

### Step 6: Add Subagents (optional)
Create agent files in `groups/{new-dept}/.claude/agents/`:
Use `.claude/skills/_templates/AGENT-TEMPLATE.md` as starting point.

## Active Departments
- [x] marketing — Marketing department
- [ ] code — Software development
- [ ] research — Research & analysis
- [ ] content — Content production
- [ ] personal — Personal assistant
