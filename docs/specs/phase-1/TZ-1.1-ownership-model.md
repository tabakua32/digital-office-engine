# TZ-1.1: Ownership Model + Group Registration

> **Phase**: 1 — General System Topology
> **Priority**: P0 (core — вся ізоляція і маршрутизація залежить від цього)
> **Sessions**: 2-3
> **Dependencies**: TZ-0.1 (skill standard для naming conventions)
> **Verdict**: ADAPT 55% | COPY 25% | BUILD 20%
> **Architecture ref**: `docs/architecture/phase-1-topology.md` §1.3, §1.4

---

## 1. Мета

Визначити модель володіння (ownership) у NanoClaw OS: як один інстанс
обслуговує одного власника з N компаніями/проектами, кожна з яких ізольована
на рівні OS-контейнерів. Описати flow реєстрації нової групи (register_group),
авторизацію між групами, та SQLite-схему для зберігання цих зв'язків.

**Без цього ТЗ**: невідомо хто має доступ куди, групи не ізольовані,
IPC авторизація не працює, scheduled tasks можуть виконуватись у чужому контексті.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Ownership Model (1:1:N)

```
1 NanoClaw Instance = 1 Owner = N Companies/Projects

Owner (admin, main group)
├── Company A (yakomanda)         — повна компанія
│   └── Subproject (course)       — наслідує company+brand від батька
├── Client B (client-x)           — повна ізоляція
└── Pilot Group (students)        — тимчасова група
```

**Три типи зв'язку між компаніями:**

| Type | Isolation | Context | Container | Use Case |
|------|-----------|---------|-----------|----------|
| **ISOLATED** | Full | Own 5 modules | Own container | Клієнт фрілансу |
| **SUBPROJECT** | Partial | Inherits company+brand, own product/audience/market | Own container | Курс, підпроект |
| **ADMIN** | None | Sees ALL | Main group | Власник (єдиний) |

#### B. Group Registration Flow

```
Owner (main TG group)
│
├── /register-group [jid] [folder] [trigger]
│   │
│   ├── 1. Validate folder name (regex: [A-Za-z0-9][A-Za-z0-9_-]{0,63})
│   ├── 2. Check JID exists in available_groups (after sync)
│   ├── 3. Create group folder: groups/{folder}/
│   │   ├── CLAUDE.md (identity template)
│   │   ├── context/ (5 empty modules from TZ-0.1)
│   │   └── memory/ (facts.jsonl, decisions.jsonl)
│   ├── 4. Write registered_groups record (SQLite)
│   ├── 5. Respond with confirmation + next steps
│   └── 6. IPC: register_group JSON message
│
└── /list-groups → show all registered + available
```

#### C. RegisteredGroup SQLite Schema

**Існуюча таблиця** (NanoClaw v1.1.3 — COPY as-is):

```sql
CREATE TABLE IF NOT EXISTS registered_groups (
  jid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  folder TEXT NOT NULL UNIQUE,
  trigger_pattern TEXT NOT NULL,
  added_at TEXT NOT NULL,
  container_config TEXT,          -- JSON: {additionalMounts, timeout}
  requires_trigger INTEGER DEFAULT 1
);
```

**Розширення для NanoClaw OS** (ADAPT — нові колонки):

```sql
ALTER TABLE registered_groups ADD COLUMN group_type TEXT DEFAULT 'isolated';
  -- 'isolated' | 'subproject' | 'admin'

ALTER TABLE registered_groups ADD COLUMN parent_folder TEXT;
  -- NULL для isolated/admin, folder батька для subproject

ALTER TABLE registered_groups ADD COLUMN context_inheritance TEXT;
  -- JSON: ["company", "brand"] — які модулі наслідуються

ALTER TABLE registered_groups ADD COLUMN status TEXT DEFAULT 'active';
  -- 'active' | 'suspended' | 'archived'

ALTER TABLE registered_groups ADD COLUMN owner_user_id TEXT;
  -- Telegram user ID власника (для авторизації)
```

#### D. RegisteredGroup TypeScript Interface

```typescript
// Extension of existing types.ts
export interface RegisteredGroup {
  name: string;
  folder: string;
  trigger: string;
  added_at: string;
  containerConfig?: ContainerConfig;
  requiresTrigger?: boolean;
  
  // NanoClaw OS extensions:
  groupType: 'isolated' | 'subproject' | 'admin';
  parentFolder?: string;           // for subprojects
  contextInheritance?: string[];   // ["company", "brand"]
  status: 'active' | 'suspended' | 'archived';
  ownerUserId?: string;            // TG user ID
}
```

#### E. Authorization Model

```
MAIN GROUP (admin):
├── register_group     ✅ (єдиний хто може)
├── list_all_groups    ✅
├── schedule cross-group tasks  ✅
├── export sessions    ✅
├── IPC send to ANY group  ✅
└── refresh_groups     ✅

NON-MAIN GROUP (isolated/subproject):
├── register_group     ❌ blocked
├── list own tasks     ✅
├── schedule own tasks ✅ (only targetJid = own JID)
├── IPC send to own JID only  ✅
└── refresh_groups     ❌ blocked

SUBPROJECT GROUP:
├── Same as NON-MAIN   ✅
├── Read parent context (company, brand)  ✅ (symlink/copy-on-read)
└── Write own context (product, audience, market)  ✅
```

#### F. Group Folder Structure

```
groups/
├── main/                     ← Admin group (MAIN_GROUP_FOLDER)
│   ├── CLAUDE.md             ← Admin identity + global context
│   ├── context/              ← Full 5 modules
│   │   ├── company/
│   │   ├── product/
│   │   ├── audience/
│   │   ├── brand/
│   │   └── market/
│   └── memory/
│       ├── CLAUDE.md          ← Runtime state
│       ├── facts.jsonl        ← Append-only facts
│       └── decisions.jsonl    ← Append-only decisions
│
├── yakomanda/                ← Company (isolated)
│   ├── CLAUDE.md
│   ├── context/ (full)
│   └── memory/
│
├── yakomanda-course/         ← Subproject
│   ├── CLAUDE.md
│   ├── context/
│   │   ├── company/ → ../../yakomanda/context/company  (symlink)
│   │   ├── brand/   → ../../yakomanda/context/brand    (symlink)
│   │   ├── product/          ← OWN
│   │   ├── audience/         ← OWN
│   │   └── market/           ← OWN
│   └── memory/
│
└── client-x/                 ← Fully isolated
    ├── CLAUDE.md
    ├── context/ (full, empty)
    └── memory/
```

### 2.2 Excluded (DEFER)

- **Multi-owner SaaS** — 1 instance = 1 owner, не змінюється
- **Dynamic group type change** — type фіксується при реєстрації
- **Cross-company context sharing** (окрім subproject → parent)
- **Automatic subproject detection** — тільки manual реєстрація
- **Group deletion** — тільки archive (status = 'archived')

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] `registered_groups` таблиця розширена 5-ма новими колонками
- [ ] Migration backward-compatible (existing groups → groupType='isolated')
- [ ] `/register-group` command створює folder + context + memory structure
- [ ] IPC `register_group` message працює через main group
- [ ] Non-main groups не можуть register_group (IPC auth check)
- [ ] Group folder validation: regex + path escape prevention
- [ ] `getAllRegisteredGroups()` повертає розширений `RegisteredGroup`

### P1 — Full MVP

- [ ] Subproject inheritance: symlinks для company/brand context
- [ ] `status` field: active/suspended/archived з відповідною поведінкою
- [ ] `ownerUserId` field: Telegram user ID для авторизації команд
- [ ] `/list-groups` command показує all groups з типами та статусами

### P2 — Extended

- [ ] Archive flow: group status → 'archived', container stops, data preserved
- [ ] Group metadata sync: periodic refresh з Telegram API

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/types.ts` | MODIFY | Extend RegisteredGroup interface |
| `src/db.ts` | MODIFY | Add ALTER TABLE migrations, update accessors |
| `src/ipc.ts` | MODIFY | Update register_group handler for new fields |
| `src/group-folder.ts` | MODIFY | Add createGroupStructure() function |
| `src/commands/register-group.ts` | CREATE | Command handler for /register-group |
| `src/commands/list-groups.ts` | CREATE | Command handler for /list-groups |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `src/db.ts` | 12-81 | Existing schema + migration pattern |
| `src/types.ts` | 30-42 | RegisteredGroup interface |
| `src/group-folder.ts` | 1-45 | Folder validation + path security |
| `src/ipc.ts` | 351-382 | Existing register_group IPC handler |
| `src/config.ts` | — | MAIN_GROUP_FOLDER, GROUPS_DIR constants |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| SQLite group registration | NanoClaw v1.1.3 `db.ts` | COPY | Base schema, accessors |
| IPC auth by sourceGroup | NanoClaw v1.1.3 `ipc.ts` | COPY | main vs non-main check |
| Folder validation regex | NanoClaw v1.1.3 `group-folder.ts` | COPY | Security pattern |
| Group discovery flow | NanoClaw v1.1.3 `container-runner.ts` | ADAPT | Add groupType/parent |
| Context module structure | Architecture §0.4 | BUILD | 5 modules per company |

### Risks

1. **Symlink in containers** — Docker/Apple Container можуть не слідувати symlinks при mount. Fallback: copy-on-read.
2. **Migration existing groups** — Existing groups без нових полів → default values must be safe.
3. **Path traversal** — Subproject parent_folder reference must be validated (no `../` escape).

---

## 5. Testing

### Unit Tests

```typescript
// group-registration.test.ts
describe('RegisteredGroup extensions', () => {
  test('new columns have safe defaults');
  test('existing groups migrate with groupType=isolated');
  test('subproject inherits parent context paths');
  test('invalid parent_folder rejected');
  test('non-main IPC register_group blocked');
  test('main IPC register_group creates full structure');
});
```

### Integration Tests

```typescript
describe('Group registration flow', () => {
  test('register → folder created → schema correct');
  test('register subproject → symlinks created');
  test('register with invalid folder → error');
  test('register duplicate folder → error');
  test('list-groups returns all with correct types');
});
```

### Manual Verification

1. Register a new isolated group via Telegram /register-group
2. Verify folder structure created correctly
3. Register a subproject with parent → verify symlinks
4. Try register from non-main group → verify blocked
5. Check SQLite: `SELECT * FROM registered_groups` → verify new columns

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Unit tests written and passing
- [ ] No regression in existing 436 tests (`npm test`)
- [ ] TypeScript compiles without errors (`npm run typecheck`)
- [ ] SQLite migration safe for existing databases
- [ ] Code reviewed (no path traversal vulnerabilities)
