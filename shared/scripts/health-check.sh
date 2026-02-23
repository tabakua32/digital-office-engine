#!/bin/bash
echo "=== Digital Office Health Check ==="
echo "Date: $(date)"
echo ""

# Process check
echo "--- Processes ---"
pgrep -f "digital-office-engine" > /dev/null 2>&1 && echo "✅ Engine running" || echo "❌ Engine NOT running"

# DB check
echo "--- Database ---"
MEMORY_COUNT=$(sqlite3 ~/digital-office-engine/shared/data/office.db "SELECT COUNT(*) FROM memory;" 2>/dev/null)
if [ $? -eq 0 ]; then
  echo "✅ DB accessible (${MEMORY_COUNT} memory entries)"
else
  echo "❌ DB error"
fi

# Disk space
echo "--- Disk ---"
df -h ~ | tail -1

# Git status
echo "--- Git ---"
cd ~/digital-office-engine && git log --oneline -1 2>/dev/null

# Last log entry
echo "--- Last Activity ---"
tail -1 ~/digital-office-engine/shared/logs/$(date +%Y-%m-%d).log 2>/dev/null || echo "No logs today"
