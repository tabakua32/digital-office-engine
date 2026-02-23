---
name: {pipeline-name}
description: {multi-step process description}
---

# {Pipeline Name}

## Overview
{What this pipeline achieves end-to-end}

## Steps

### Step 1: {Name}
- Action: {what to do}
- Tool: {MCP tool or bash command}
- Output: save to workspace/{step1-result}.md
- ✅ Checkpoint

### Step 2: {Name}
- Input: workspace/{step1-result}.md
- Action: {what to do}
- Output: save to workspace/{step2-result}.md
- ✅ Checkpoint

### Step N: Deliver
- Compile all results
- Send to user for approval
- If approved → move to output/{date}/
- ✅ Final checkpoint

## Recovery
If session interrupted → read workspace/pipeline-state.md → continue from last checkpoint

## Cleanup
After completion → archive workspace/ files → clear pipeline-state.md
