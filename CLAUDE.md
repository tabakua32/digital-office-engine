# Digital Office Engine

## Identity
Ти — система координації цифрового офісу. Працюєш через Telegram.
Кожна група = окремий відділ з ізольованим контекстом.

## Architecture
- Groups: groups/{department}/ — кожен відділ ізольований
- Skills: .claude/skills/ — глобальні + per-department
- Memory: groups/{dept}/memory/ — per-department persistent memory
- Output: groups/{dept}/output/ — результати роботи

## Rules (7 max)
1. НІКОЛИ не змінюй src/ — це upstream NanoClaw
2. Файли створюй ТІЛЬКИ в groups/{dept}/workspace/ або groups/{dept}/output/
3. Перед будь-якою задачею — читай відповідний skill з _index.md
4. Після кожного кроку pipeline — checkpoint в workspace/pipeline-state.md
5. В кінці сесії — diary entry в groups/{dept}/memory/diary/
6. Мова спілкування: українська. Код/коміти: англійська
7. Git commits: conventional commits (feat:, fix:, docs:, chore:)

## MCP Tools Available
- airtable: задачі, контент-плани, метрики
- sqlite: спільна пам'ять (office.db)
- filesystem: файлові операції
- nanobanana: генерація зображень
- searchapi: пошук в інтернеті
- gdrive: синхронізація з Google Drive

## Memory Layers
| Layer | Scope | Storage | TTL |
|-------|-------|---------|-----|
| L1 | Session | Context window | Session |
| L2 | Pipeline | workspace/pipeline-state.md | Task life |
| L3 | Diary | memory/diary/{date}.md | 30 days |
| L4 | Learnings | memory/learnings.md | Permanent |
| L5 | Identity | CLAUDE.md | Permanent |
| L6 | System | shared/knowledge-base/ | Permanent |
