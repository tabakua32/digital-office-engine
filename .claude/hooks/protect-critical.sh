#!/bin/bash
# PreToolUse Hook — protect critical files from accidental modification
# Blocks: .env files, src/ directory
# Returns exit code 2 to block the tool call

TOOL_INPUT="$CLAUDE_TOOL_INPUT"

# Block .env file operations
if echo "$TOOL_INPUT" | grep -qE '\.env'; then
  echo "BLOCKED: Cannot modify .env files. Edit manually." >&2
  exit 2
fi

# Block src/ modifications
if echo "$TOOL_INPUT" | grep -qE '"file_path".*src/'; then
  echo "BLOCKED: src/ is upstream NanoClaw. Submit upstream PR instead." >&2
  exit 2
fi

exit 0
