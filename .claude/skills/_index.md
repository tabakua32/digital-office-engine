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

## Department Skills
Each department has own _index.md at:
`groups/{department}/.claude/skills/_index.md`

## Rule
Before ANY task → find matching skill in index → read it fully → execute.
If no skill exists → complete task → create new skill from template.
