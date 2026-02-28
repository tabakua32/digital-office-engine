#!/bin/bash
# Sync output folders to Google Drive via rclone
# Requires: rclone configured with 'gdrive' remote
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for dept_dir in "$PROJECT_ROOT"/groups/*/output/; do
  dept=$(basename "$(dirname "$dept_dir")")
  if [ -d "$dept_dir" ] && [ "$(ls -A "$dept_dir" 2>/dev/null)" ]; then
    rclone sync "$dept_dir" "gdrive:digital-office/${dept}/" --exclude "*.tmp" --exclude ".gitkeep" 2>/dev/null || true
  fi
done

echo "[$(date)] Google Drive sync complete"
