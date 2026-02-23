# Digital Office Engine — Architecture

## Overview
Fork of [NanoClaw](https://github.com/qwibitai/nanoclaw) tuned as a multi-department digital office.
Single Node.js process → Telegram → Container isolation → Claude Agent SDK.

## Components

```
┌─────────────────────────────────────────────────────┐
│                    Telegram Bots                     │
│  @office_main_bot  @office_marketing_bot  ...       │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│              NanoClaw Orchestrator                    │
│  src/index.ts → Router → Group Queue → Scheduler     │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│           Container Runtime (Docker/Apple)            │
│  Per-group isolation → Claude Agent SDK containers   │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│              MCP Tools Layer                          │
│  SQLite │ Airtable │ Nanobanana │ SearchAPI │ GDrive │
└─────────────────────────────────────────────────────┘
```

## Data Flow
```
Telegram Message
  → src/channels/telegram.ts (Grammy handler)
  → src/router.ts (route to group)
  → src/group-queue.ts (queue management)
  → src/container-runner.ts (spawn container)
  → Container: Claude Agent SDK + CLAUDE.md + MCP tools
  → Response back through Telegram
```

## Memory Flow
```
Session (L1, context window)
  → Checkpoint (L2, workspace/pipeline-state.md)
  → Diary (L3, memory/diary/{date}.md)
  → Weekly /reflect
  → Learnings (L4, memory/learnings.md)
  → CLAUDE.md updates (L5, identity rules)
  → Knowledge Base (L6, shared/knowledge-base/)
```

## Directory Structure
- `src/` — NanoClaw core (DO NOT MODIFY — upstream sync)
- `groups/{dept}/` — Per-department isolated environments
- `.claude/skills/` — Global + system skills
- `shared/` — Cross-department resources (DB, knowledge base, scripts)
- `config/` — Portable configuration references
- `infrastructure/` — launchd/systemd service files

## Key Design Decisions
1. **Never modify src/**: Upstream NanoClaw updates via `git fetch upstream`
2. **Skills-first**: Every repeatable task becomes a skill with checkpoint
3. **6-layer memory**: Survives context compaction via PreCompact hook
4. **Department isolation**: Each dept gets own container, memory, output
5. **Airtable for tasks**: External task board, not in-memory
