#!/bin/bash
# Stop Hook — auto git backup of working files
cd ~/digital-office-engine

# Only if there are changes in tracked directories
if [ -n "$(git status --porcelain groups/ shared/ .claude/ 2>/dev/null)" ]; then
  git add groups/ shared/knowledge-base/ .claude/skills/ .claude/commands/ .claude/hooks/ .claude/agents/ .claude/settings.json 2>/dev/null
  git commit -m "chore: auto-backup $(date +%Y-%m-%d-%H%M)" 2>/dev/null
  git push origin main 2>/dev/null || true
fi
