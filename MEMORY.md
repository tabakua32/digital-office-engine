# MEMORY.md — Cross-Session Persistent State
Last updated: 2026-02-28

## Project State
- Fork: tabakua32/digital-office-engine ← qwibitai/nanoclaw
- 5+ commits ahead, 0 behind upstream
- Active departments: main (Telegram), marketing (scaffold), global
- Architecture: 7 phases complete → docs/architecture/
- Skill Factory: Track B, F-0..F-6 all PENDING

## Recent Decisions
- 2026-02-28: Architecture docs moved into repo (docs-as-code)
- 2026-02-28: Hardcoded paths → dynamic resolution (PROJECT_ROOT pattern)
- 2026-02-28: src/ never modified (upstream PR strategy)
- 2026-02-28: Branching strategy: main + skill-factory/{phase} + feat/fix

## Current Focus
- Track B: Skill Factory phase F-0 (Foundation)
- Next: Create foundation skills (standard, taxonomy, evaluation, handoff)

## Known Issues
- Airtable MCP not configured (needs API key)
- Google Drive MCP not configured (needs rclone setup)
- Marketing department skills directories are empty scaffolds
- .mcp.json uses absolute paths (update after project relocation)

## Key Paths
- Architecture: docs/architecture/README.md
- Skills: .claude/skills/_index.md
- Departments: groups/{dept}/CLAUDE.md
- Database: shared/data/office.db
- Hooks: .claude/hooks/
