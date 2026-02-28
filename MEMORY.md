# MEMORY.md — Cross-Session Persistent State
Last updated: 2026-02-28

## Project State
- Fork: tabakua32/digital-office-engine ← qwibitai/nanoclaw
- 9+ commits ahead, 0 behind upstream
- Active departments: main (Telegram), marketing (scaffold), global
- Architecture: 7 phases complete → docs/architecture/
- Skill Factory: Track B, F-0..F-6 all PENDING
- Security audit: 2026-02-28 PASSED (vibecoder-v2 compliance)
- Auto-accept: configured (no prompts for standard dev operations)

## Recent Decisions
- 2026-02-28: Architecture docs moved into repo (docs-as-code)
- 2026-02-28: Hardcoded paths → dynamic resolution (PROJECT_ROOT pattern)
- 2026-02-28: src/ never modified (upstream PR strategy)
- 2026-02-28: Branching strategy: main + skill-factory/{phase} + feat/fix
- 2026-02-28: Security audit — removed dangerous rm auto-allow, added deny for push --force, reset --hard, .pem/.key reads
- 2026-02-28: Plugin skills integrated into _index.md for discoverability

## Current Focus
- Track B: Skill Factory phase F-0 (Foundation)
- Next: Create foundation skills (standard, taxonomy, evaluation, handoff)

## Hooks (5 total)
| Hook | Event | Purpose |
|------|-------|---------|
| pre-compact.sh | PreCompact | Save state before context compaction |
| session-log.sh | Stop | Log session end timestamp |
| git-backup.sh | Stop | Auto-commit and push working files |
| protect-critical.sh | PreToolUse (Edit/Write) | Block .env and src/ modifications |
| notify.sh | Notification | macOS desktop notification |

## Known Issues
- Airtable MCP not configured (needs API key)
- Google Drive MCP not configured (needs rclone setup)
- Marketing department skills directories are empty scaffolds

## Key Paths
- Architecture: docs/architecture/README.md
- Skills: .claude/skills/_index.md
- Plugin skills: .claude/skills/_index.md § "Plugin Skills"
- Departments: groups/{dept}/CLAUDE.md
- Database: shared/data/office.db
- Hooks: .claude/hooks/
- Phase 0 guide: docs/PHASE-0-INSTRUCTIONS.md
