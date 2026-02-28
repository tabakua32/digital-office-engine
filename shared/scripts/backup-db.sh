#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DB_PATH="$PROJECT_ROOT/shared/data/office.db"
BACKUP_DIR="$PROJECT_ROOT/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d)
sqlite3 "$DB_PATH" ".dump" > "$BACKUP_DIR/office-${TIMESTAMP}.sql"

# Keep last 30 days
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete 2>/dev/null || true

echo "[$(date)] DB backup: office-${TIMESTAMP}.sql"
