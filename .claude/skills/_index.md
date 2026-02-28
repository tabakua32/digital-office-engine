# Skills Index — Digital Office Engine

## System Skills (always available)
| Skill | Path | Purpose |
|-------|------|---------|
| checkpoint | system/checkpoint/SKILL.md | Save pipeline state after each step |
| diary | system/diary/SKILL.md | Write session diary entry |
| reflect | system/reflect/SKILL.md | Analyze diary → update CLAUDE.md |
| file-ops | system/file-ops/SKILL.md | Create/edit tables, presentations |

## NanoClaw Built-in Skills
| Skill | Path | Purpose |
|-------|------|---------|
| add-telegram | add-telegram/SKILL.md | Add Telegram channel |
| add-voice-transcription | add-voice-transcription/SKILL.md | Add voice message transcription |
| add-telegram-swarm | add-telegram-swarm/SKILL.md | Agent swarm for Telegram |
| setup | setup/SKILL.md | Initial NanoClaw setup |
| update | update/SKILL.md | Update from upstream |
| customize | customize/SKILL.md | Add custom capabilities |

## Local Skills
| Skill | Path | Purpose |
|-------|------|---------|
| vibecoder-v2 | vibecoder-v2/SKILL.md | Claude Code best practices, security, hooks, recovery |

## Plugin Skills (auto-loaded via enabledPlugins)

Invoked via `Skill` tool. Example: `/brainstorming`, `/systematic-debugging`

### Planning & Design
| Skill | Plugin | Purpose |
|-------|--------|---------|
| brainstorming | superpowers | Turn ideas into validated designs |
| writing-plans | superpowers | Create detailed implementation plans |
| frontend-design | frontend-design | UI/UX design implementation |

### Implementation
| Skill | Plugin | Purpose |
|-------|--------|---------|
| executing-plans | superpowers | Execute implementation plans step-by-step |
| subagent-driven-development | superpowers | Parallel development with subagents |
| dispatching-parallel-agents | superpowers | Run multiple agents concurrently |

### Quality & Review
| Skill | Plugin | Purpose |
|-------|--------|---------|
| verification-before-completion | superpowers | Verify changes before finishing |
| requesting-code-review | superpowers | Request code review from Claude |
| receiving-code-review | superpowers | Process code review feedback |
| code-review | pr-review-toolkit | Full PR code review suite |
| code-simplifier | code-simplifier | Simplify and refine code |

### Testing & Debugging
| Skill | Plugin | Purpose |
|-------|--------|---------|
| systematic-debugging | superpowers | Structured debugging workflow |
| test-driven-development | superpowers | TDD workflow (Anthropic favorite) |

### Git & Branching
| Skill | Plugin | Purpose |
|-------|--------|---------|
| finishing-a-development-branch | superpowers | Complete and merge feature branches |
| using-git-worktrees | superpowers | Parallel development in worktrees |

### Meta & Extension
| Skill | Plugin | Purpose |
|-------|--------|---------|
| writing-skills | superpowers | Create new skills |
| skill-creator | skill-creator | Generate skill from template |
| writing-rules | hookify | Create hooks and rules |
| plugin-dev (7 skills) | plugin-dev | Agent, command, hook, MCP, skill development |

## Department Skills
Each department has own _index.md at:
`groups/{department}/.claude/skills/_index.md`

## Rule
Before ANY task → find matching skill in index → read it fully → execute.
If no skill exists → complete task → create new skill from template.
