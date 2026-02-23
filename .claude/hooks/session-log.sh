#!/bin/bash
# Stop Hook — logs session end
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_DIR=~/digital-office-engine/shared/logs
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
echo "[$TIMESTAMP] [SESSION_END] Session completed" >> "$LOG_FILE"
