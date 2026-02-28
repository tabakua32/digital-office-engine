#!/bin/bash
set -e
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Pull latest
git pull origin main --rebase 2>/dev/null || git pull origin main

# Push local changes (memory, output, diary)
if [ -n "$(git status --porcelain)" ]; then
  git add groups/*/memory/ groups/*/output/ shared/data/ backups/ 2>/dev/null || true
  git commit -m "sync: $(hostname) $(date +%Y-%m-%d-%H%M)" 2>/dev/null || true
  git push origin main 2>/dev/null || true
fi

echo "[$(date)] Sync complete"
