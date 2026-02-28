#!/bin/bash
# Stop Hook — logs session end
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/shared/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
echo "[$TIMESTAMP] [SESSION_END] Session completed" >> "$LOG_FILE"
