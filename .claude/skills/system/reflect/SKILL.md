---
name: reflect
description: Analyze diary entries and update agent CLAUDE.md with learnings
---
# Reflect — Weekly Knowledge Consolidation

## When to Use
- Weekly (scheduled) or manually via /reflect
- Analyzes last 7 days of diary entries

## Process
1. Read all files in groups/{agent}/memory/diary/ from last 7 days
2. Read current groups/{agent}/CLAUDE.md
3. Read groups/{agent}/memory/learnings.md
4. Identify patterns: what consistently works/fails
5. Update learnings.md with new insights
6. If a learning is critical (pattern > 3 times) → propose CLAUDE.md update
7. Archive old diary entries (> 30 days) to SQLite

## Output
Updated learnings.md with:
```markdown
# Learnings — {Department}
Last updated: {date}

## What Works
- {pattern}: {evidence from diary}

## What Doesn't Work
- {anti-pattern}: {evidence}

## Proposed CLAUDE.md Changes
- Rule {N}: {old} → {new} (reason: {diary evidence})
```

## Constraints
- CLAUDE.md stays under 7 rules
- New rules REPLACE underperforming ones, not ADD
- Always show proposed changes before applying
