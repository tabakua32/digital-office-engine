---
name: checkpoint
description: Save pipeline state after each step for recovery
---
# Checkpoint Pattern

## Usage
After every significant step in a pipeline, save state:

File: groups/{agent}/workspace/pipeline-state.md

```markdown
# Pipeline State
- Pipeline: {name}
- Started: {datetime}
- Current Step: {N} of {total}
- Last Completed: Step {N-1} — {description}

## Completed Steps
- [x] Step 1: {result summary}
- [x] Step 2: {result summary}
- [ ] Step 3: {next action}

## Artifacts
- workspace/step1-result.md
- workspace/step2-result.md
```

## Recovery
On session start, if pipeline-state.md exists and has incomplete steps:
→ Read it → Continue from last completed step

## When to Checkpoint
- After any MCP tool call that produces data
- After file creation/modification
- Before any operation that might fail
- At natural boundaries in multi-step tasks
