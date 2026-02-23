#!/bin/bash
DB_PATH=~/digital-office-engine/shared/data/office.db
BACKUP_DIR=~/digital-office-engine/backups
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d)
sqlite3 "$DB_PATH" ".dump" > "$BACKUP_DIR/office-${TIMESTAMP}.sql"

# Keep last 30 days
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete 2>/dev/null || true

echo "[$(date)] DB backup: office-${TIMESTAMP}.sql"
