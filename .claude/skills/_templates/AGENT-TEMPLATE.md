---
name: {agent-name}
description: {when this agent should be delegated to}
model: sonnet
tools: [Read, Write, Edit, Bash, Grep, Glob]
memory: project
---

# {Agent Name}

## Role
{One sentence role description}

## Skills (preloaded)
- Read: ../.claude/skills/{skill}/SKILL.md

## Rules
1. Always read skill before starting task
2. Output results in structured format
3. Write learnings to ../memory/learnings.md

## Output Format
```json
{
  "status": "success|error",
  "result": "...",
  "next_steps": []
}
```
