# TZ-1.4: Forum Thread Hierarchy + Context Modules

> **Phase**: 1 — General System Topology
> **Priority**: P1 (розширює routing, не блокує базову роботу)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.2 (canonical store, layer 2 structure)
> **Verdict**: BUILD 50% | ADAPT 35% | COPY 15%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.4, §0.10

---

## 1. Мета

Реалізувати Forum Thread Hierarchy — систему де кожна тема (topic) у Telegram
суперчаті стає routing domain для конкретних скілів. Визначити Context Modules —
17 markdown-файлів які описують DNA компанії (company, product, audience, brand,
market) та inject'яться в system prompt агента перед виконанням.

**Без цього ТЗ**: агент не знає в якій темі він відповідає, routing працює
тільки по тригерах (/command), scheduled reports летять в General замість
цільової теми, контекст компанії ніде не зберігається.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Thread Hierarchy Schema

```typescript
interface ThreadHierarchy {
  group_id: string;                    // folder name (e.g., "yakomanda")
  chat_id: number;                     // Telegram chat ID
  has_forums: boolean;                 // true if Forums enabled
  threads: ThreadInfo[];
  default_thread: number;              // thread_id for unmatched messages
  unmatched_routing: 'general' | 'classify';  // routing strategy
}

interface ThreadInfo {
  thread_id: number;
  name: string;                        // e.g., "✍️ Контент"
  icon: string;                        // emoji icon
  is_general: boolean;
  routing_domain: string | null;       // e.g., "marketing/content"
  routing_hint: string;                // comma-separated keywords
  allowed_skills: string[];            // skill IDs or ["*"]
  scheduled_reports: boolean;          // can receive scheduled output
}
```

**Storage**: `groups/{folder}/thread_hierarchy.json`

**SQLite index** (for fast thread lookup):

```sql
CREATE TABLE IF NOT EXISTS thread_routing (
  chat_id INTEGER NOT NULL,
  thread_id INTEGER NOT NULL,
  group_folder TEXT NOT NULL,
  routing_domain TEXT,
  routing_hint TEXT,
  allowed_skills TEXT,          -- JSON array
  PRIMARY KEY (chat_id, thread_id),
  FOREIGN KEY (group_folder) REFERENCES registered_groups(folder)
);
```

#### B. Thread Discovery Flow

```
Bot added to supergroup with Forums:
│
├── 1. telegram.ts: detect has_forums flag from chat info
├── 2. getForumTopicIconStickers() → get available icons
├── 3. getForumTopics() → list all existing topics
│      (Bot API: no direct method → scan recent messages
│       for message_thread_id values, or use MTProto in Phase 2.5)
├── 4. Build ThreadHierarchy with defaults:
│      ├── routing_domain = null (owner configures)
│      ├── allowed_skills = ["*"]
│      └── scheduled_reports = false
├── 5. Write thread_hierarchy.json to group folder
├── 6. Insert into thread_routing SQLite table
└── 7. Prompt owner: "Forum topics discovered. Configure routing?"
       /configure-threads → interactive setup via inline keyboards
```

#### C. Thread-Aware Message Routing

```
Message arrives in thread_id=43 ("✍️ Контент"):
│
├── 1. Extract message_thread_id from Telegram update
├── 2. SQLite lookup: thread_routing WHERE chat_id AND thread_id
├── 3. Enrich message context:
│      {
│        content: "напиши статтю про AI",
│        thread: {
│          id: 43,
│          name: "✍️ Контент",
│          domain: "marketing/content",
│          hint: "articles, posts, email, copy"
│        }
│      }
├── 4. Route to skill:
│      ├── If thread has routing_domain → filter skills by domain
│      ├── If thread has allowed_skills → restrict to those
│      ├── If thread is General → classify by content (NLU or Claude)
│      └── If no forums → use trigger-based routing (fallback)
├── 5. Execute skill in container
└── 6. Reply with message_thread_id=43 (stay in same thread)
```

#### D. Thread Context Injection (System Prompt)

```
system_prompt = [
  foundation_prompt,        // Layer 1 (cached)
  company_context,          // Layer 2 — company DNA
  thread_context,           // Layer 2 — THREAD HIERARCHY ← NEW
  skill_prompt,             // Layer 3 — skill SKILL.md
  memory                    // runtime — CLAUDE.md + facts
]
```

Thread context template:

```markdown
## Current Context
You are responding in forum thread "{thread.name}"
(thread_id: {thread.id}) of supergroup "{group.name}".

Thread hierarchy of this group:
{for thread in threads}
{thread.icon} {thread.name}{" ← ВИ ТУТ" if current} — {thread.routing_hint}
{/for}

RULES:
- Focus on {thread.routing_domain} tasks
- Always reply in this thread (thread_id={thread.id})
- If task is outside your domain, suggest the right thread
- Reference chat history ONLY from this thread
```

#### E. Context Modules (Layer 2)

**5 категорій × 17 файлів:**

```
companies/{folder}/context/
├── company/
│   ├── identity.md       ← Назва, місія, цінності, USP
│   ├── team.md           ← Структура команди, ролі, зони відповідальності
│   └── operations.md     ← Процеси, інструменти, SLA
│
├── product/
│   ├── spec.md           ← Опис продукту/послуги, характеристики
│   ├── pricing.md        ← Ціни, тарифи, знижки, модель монетизації
│   └── positioning.md    ← Ніша, конкурентна перевага, benefits
│
├── audience/
│   ├── icp.md            ← Ideal Customer Profile (демографія, психографія)
│   ├── jtbd.md           ← Jobs-to-be-Done (задачі клієнта)
│   ├── voc.md            ← Voice of Customer (цитати, біль, бажання)
│   └── awareness.md      ← Рівні обізнаності (5 levels of awareness)
│
├── brand/
│   ├── voice.md          ← Tone of Voice, стиль комунікації
│   ├── visual.md         ← Фірмовий стиль, кольори, шрифти
│   └── guidelines.md     ← Брендбук, do's & don'ts
│
└── market/
    ├── intelligence.md   ← Тренди ринку, розмір, динаміка
    ├── competitors.md    ← Конкуренти, їх сильні/слабкі сторони
    ├── channels.md       ← Канали розповсюдження, performance
    └── geo_aeo.md        ← Geo-таргетинг, answer engine optimization
```

**Schema для кожного файлу** (приклад identity.md):

```markdown
---
module: company/identity
version: "1.0"
last_updated: "2026-03-01"
confidence: high            # high | medium | low | draft
---

# Company Identity

## Name
{company_name}

## Mission
{1-2 sentences}

## Core Values
- {value_1}
- {value_2}

## Unique Selling Proposition
{USP statement}

## Key Differentiators
1. {differentiator_1}
2. {differentiator_2}
```

**Context injection logic:**

```typescript
function buildContextForSkill(
  group: RegisteredGroup,
  skill: SkillManifest,
): string {
  const contextParts: string[] = [];
  
  // Read only modules listed in skill's context_deps
  for (const dep of skill.context_deps) {
    const modulePath = path.join(
      GROUPS_DIR, group.folder, 'context', dep + '.md'
    );
    if (fs.existsSync(modulePath)) {
      contextParts.push(fs.readFileSync(modulePath, 'utf-8'));
    }
  }
  
  return contextParts.join('\n\n---\n\n');
}
```

#### F. Backward Compatibility

| Scenario | has_forums | Routing | Threading |
|----------|-----------|---------|-----------|
| Supergroup with Forums | true | domain-based | message_thread_id |
| Regular group | false | trigger-based only | no thread_id |
| Private chat (DM) | false | command-based only | no thread_id |
| Channel (linked) | false | publish only | no routing |

### 2.2 Excluded (DEFER)

- **Dynamic topic creation** by agent (campaign threads) — Phase 2.5
- **Auto-classify routing_domain** from topic name — P2
- **Context extraction agents** (semi-auto filling of context modules) — Phase 4
- **Context versioning** (Git history tracking per module) — Phase 4
- **Vector search** over context modules — Phase 4

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] ThreadHierarchy JSON schema defined and validated
- [ ] `thread_routing` SQLite table created
- [ ] Thread discovery: detect Forums → build hierarchy → store
- [ ] Thread-aware routing: message_thread_id → domain → skill filter
- [ ] Thread context injection in system prompt
- [ ] Backward compatibility: groups without Forums work as before

### P1 — Full MVP

- [ ] 17 context module files scaffolded with schema templates
- [ ] `buildContextForSkill()` reads only needed modules (context_deps)
- [ ] `/configure-threads` command for owner to set routing domains
- [ ] Scheduled tasks include target_thread_id
- [ ] Thread hierarchy refresh on demand (/refresh-threads)

### P2 — Extended

- [ ] Context module confidence tracking (high/medium/low/draft)
- [ ] Auto-suggest thread → domain mapping from topic name
- [ ] Context completeness report (/context-status)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/db.ts` | MODIFY | Add thread_routing table |
| `src/channels/telegram.ts` | MODIFY | Extract message_thread_id, forum detection |
| `src/forum-hierarchy.ts` | CREATE | ThreadHierarchy management |
| `src/context-loader.ts` | CREATE | buildContextForSkill() + module reader |
| `src/commands/configure-threads.ts` | CREATE | Interactive thread configuration |
| `groups/{folder}/thread_hierarchy.json` | CREATE | Per-group thread topology |
| `companies/{folder}/context/**/*.md` | CREATE | 17 context module templates |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-0-foundation.md` | 273-492 | Full forum hierarchy spec |
| `docs/architecture/phase-0-foundation.md` | 816-870 | Context modules design |
| `docs/architecture/phase-1-topology.md` | 312-363 | Canonical store companies/ |
| `src/channels/telegram.ts` | — | Existing Telegram adapter |
| `src/container-runner.ts` | — | How context is mounted |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| message_thread_id handling | grammY framework | ADAPT | Thread extraction |
| Forum topic scanning | Telegram Bot API docs | BUILD | No direct getForumTopics method |
| Context module markdown | YaKomanda 52 blocks | ADAPT | Structure for context files |
| System prompt layering | Anthropic cookbooks | ADAPT | Foundation + context + skill |
| Thread routing table | — | BUILD | No existing reference |

### Risks

1. **Bot API limitation**: No `getForumTopics()` method in Bot API. Workaround: scan recent messages for unique thread_ids, or use MTProto (Phase 2.5).
2. **Thread hierarchy stale**: Topics renamed/created/deleted by humans → hierarchy out of sync. Solution: periodic refresh + webhook for topic events.
3. **Context file size**: Large context modules → token budget exhaustion. Solution: context budget management (TZ-3.3), progressive loading.

---

## 5. Testing

### Unit Tests

```typescript
describe('Thread Hierarchy', () => {
  test('buildThreadHierarchy from topic list');
  test('thread routing lookup returns correct domain');
  test('backward compat: group without forums → no routing');
  test('thread context template generation');
  test('default thread fallback for unmatched messages');
});

describe('Context Modules', () => {
  test('buildContextForSkill loads only context_deps');
  test('missing module file handled gracefully');
  test('module YAML frontmatter parsed');
  test('empty module returns empty string');
  test('subproject inherits parent modules via symlink');
});

describe('Thread-aware routing', () => {
  test('message in domain thread → domain skills only');
  test('message in General → all skills allowed');
  test('scheduled report → correct target thread');
});
```

### Integration Tests

```typescript
describe('Forum integration', () => {
  test('bot joins forum group → hierarchy discovered');
  test('message in thread → routed → replied in same thread');
  test('configure-threads → updates hierarchy + SQLite');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] ThreadHierarchy JSON validated against schema
- [ ] 17 context module templates created with YAML frontmatter
- [ ] Backward compatibility tested (groups with/without Forums)
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors
