#!/bin/bash
# PreCompact Hook — saves session state before context compaction
# This message is injected into Claude's context to trigger diary + checkpoint

TIMESTAMP=$(date +%Y-%m-%d-%H%M)

cat << HOOK_EOF
{
  "message": "⚠️ CONTEXT COMPACTION IMMINENT. Before compaction, you MUST:\n1. Save current work state to groups/{current-dept}/workspace/pipeline-state.md\n2. Write diary entry to groups/{current-dept}/memory/diary/${TIMESTAMP}.md\n3. List all pending tasks and next steps clearly\nThis ensures continuity after compaction."
}
HOOK_EOF
