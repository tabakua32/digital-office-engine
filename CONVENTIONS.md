# File & Naming Conventions

## Directory Rules
- Agents create files ONLY in their groups/{dept}/workspace/ or groups/{dept}/output/
- Temporary files → workspace/ (auto-cleaned weekly)
- Final results → output/{YYYY-MM-DD}/ (permanent, synced to Google Drive)
- Memory → memory/ (diary, learnings)

## Naming
- Files: kebab-case (content-plan-week-08.md)
- Directories: kebab-case
- Skills: {category}/{skill-name}/SKILL.md
- Agents: {role-name}.md
- Git commits: conventional (feat:, fix:, docs:, chore:)

## Language
- User communication: Ukrainian
- Code, comments, commits: English
- File names: English

## Forbidden
- No files in repo root (except CLAUDE.md, CONVENTIONS.md, .mcp.json, .gitignore)
- No spaces in file names
- No files > 10MB in git (use Google Drive for large files)
- No secrets in any tracked file
- No modifications to src/ (upstream NanoClaw code)
