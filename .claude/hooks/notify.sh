#!/bin/bash
# Notification Hook — macOS desktop notification when Claude needs attention
osascript -e 'display notification "Claude needs your attention" with title "Digital Office Engine"' 2>/dev/null || true
