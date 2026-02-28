#!/bin/bash
# Stop Hook — auto git backup of working files
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Only if there are changes in tracked directories
if [ -n "$(git status --porcelain groups/ shared/ .claude/ MEMORY.md docs/ 2>/dev/null)" ]; then
  git add MEMORY.md docs/ groups/ shared/knowledge-base/ .claude/skills/ .claude/commands/ .claude/hooks/ .claude/agents/ .claude/settings.json 2>/dev/null
  git commit -m "chore: auto-backup $(date +%Y-%m-%d-%H%M)" 2>/dev/null
  git push origin main 2>/dev/null || true
fi
