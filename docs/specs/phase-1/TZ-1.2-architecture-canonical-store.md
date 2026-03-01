# TZ-1.2: 4-Layer Architecture + Canonical Store

> **Phase**: 1 — General System Topology
> **Priority**: P0 (все що стосується структури даних і шарів залежить від цього)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.1 (ownership model, group types)
> **Verdict**: ADAPT 50% | COPY 20% | BUILD 30%
> **Architecture ref**: `docs/architecture/phase-1-topology.md` §1.4, §1.5

---

## 1. Мета

Визначити 4-шарову архітектуру NanoClaw OS (Runtime → Foundation → Context → Skills)
та Canonical Store — єдине джерело правди у вигляді Git-репозиторію з чіткою
файловою структурою. Описати SQLite-схему для оперативного стану та mapping
між canonical store і runtime paths.

**Без цього ТЗ**: немає єдиної схеми зберігання, скіли не знають де шукати
контекст, міграції ламають дані, шари не розділені — зміна TG адаптера ламає скіли.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. 4-Layer Architecture

```
╔════════════════════════════════════════════════════════════╗
║  LAYER 3: DOMAIN SKILLS (platform-agnostic)               ║
║  marketing/ │ dev-ops/ │ visual/ │ data/ │ communication/ │ meta/  ║
║  × agent | skill | connector | command | module | process  ║
║  Один SKILL.md → працює на БУДЬ-ЯКОМУ runtime              ║
╠════════════════════════════════════════════════════════════╣
║  LAYER 2: CONTEXT MODULES (per-company)                    ║
║  company/ │ product/ │ audience/ │ brand/ │ market/         ║
║  17 файлів, structured markdown зі schema                  ║
╠════════════════════════════════════════════════════════════╣
║  LAYER 1: FOUNDATION (one-time build)                      ║
║  Skill Standard │ Taxonomy │ Evaluation │ Handoff Protocol  ║
║  Output Templates │ Channel Adaptors │ Process Templates    ║
╠════════════════════════════════════════════════════════════╣
║  RUNTIME LAYER (platform-specific thin adapter)             ║
║  NanoClaw: telegram.ts, container-runner.ts, group-queue.ts ║
║  + Claude.ai, Claude Code, Cowork (auxiliary)               ║
╚════════════════════════════════════════════════════════════╝

KEY PRINCIPLE: Layers 1-3 = PLATFORM-AGNOSTIC investment.
Runtime = thin adapter. Telegram gone → replace telegram.ts only.
```

**Layer isolation rules:**

| Rule | Description |
|------|-------------|
| Skills DON'T know about Telegram | No `sendMessage()`, no `MarkdownV2` in SKILL.md |
| Skills DON'T know about NanoClaw | No `container-runner`, no `ipc.ts` references |
| Skills KNOW about Context (Layer 2) | Read context_deps from YAML frontmatter |
| Skills KNOW about Standard (Layer 1) | Follow skill standard, output templates |
| Runtime KNOWS about everything | Orchestrates all layers |

#### B. Canonical Store (Git Repository)

```
yakomanda-os/                        ← Git repo (private)
│
├── foundation/                      ← LAYER 1
│   ├── skill_standard.md
│   ├── skill_taxonomy.md
│   ├── evaluation_framework.md
│   ├── handoff_protocol.md
│   ├── connector_standard.md
│   ├── output_templates/
│   │   ├── analytical.md
│   │   ├── generative.md
│   │   ├── transformational.md
│   │   └── orchestration.md
│   ├── channel_adaptors/
│   │   ├── telegram.md
│   │   ├── whatsapp.md
│   │   ├── web_artifact.md
│   │   └── file_output.md
│   └── process_templates/
│       ├── campaign_launch.md
│       ├── content_pipeline.md
│       ├── client_onboarding.md
│       ├── competitive_intel.md
│       └── skill_creation.md
│
├── skills/                          ← LAYER 3
│   ├── marketing/
│   │   ├── market-intelligence/
│   │   ├── customer-analysis/
│   │   ├── pmf/
│   │   ├── positioning/
│   │   ├── offer/
│   │   ├── brand/
│   │   ├── content/
│   │   ├── geo-aeo/
│   │   ├── distribution/
│   │   ├── conversion/
│   │   ├── cx/
│   │   ├── retention/
│   │   ├── analytics/
│   │   └── scaling/
│   ├── dev-ops/
│   ├── visual/
│   ├── data/
│   ├── communication/
│   └── meta/
│
├── connectors/                      ← MCP configs
│   ├── telegram-mcp/
│   ├── notion-mcp/
│   ├── google-ads-mcp/
│   └── .../
│
├── companies/                       ← LAYER 2 (per-company)
│   ├── yakomanda/
│   │   ├── context/
│   │   │   ├── company/ (identity.md, team.md, operations.md)
│   │   │   ├── product/ (spec.md, pricing.md, positioning.md)
│   │   │   ├── audience/ (icp.md, jtbd.md, voc.md, awareness.md)
│   │   │   ├── brand/ (voice.md, visual.md, guidelines.md)
│   │   │   └── market/ (intelligence.md, competitors.md, channels.md, geo_aeo.md)
│   │   └── memory/
│   │       ├── CLAUDE.md
│   │       ├── facts.jsonl
│   │       └── decisions.jsonl
│   └── client-x/
│       ├── context/
│       └── memory/
│
└── runtime/                         ← Mapping configs
    ├── nanoclaw/
    │   ├── sync.sh                  ← git pull → mount refresh
    │   └── mapping.yaml             ← canonical → NanoClaw paths
    ├── claude-code/
    │   └── mapping.yaml
    └── claude-ai/
        └── mapping.yaml
```

#### C. SQLite Operational Schema (Extension)

**Існуючі таблиці (NanoClaw v1.1.3 — COPY):**
- `chats` — chat metadata (jid, name, last_message_time, channel, is_group)
- `messages` — message history (id, chat_jid, sender, content, timestamp)
- `registered_groups` — group registration (+ TZ-1.1 extensions)
- `scheduled_tasks` — cron/interval/once tasks
- `task_run_logs` — execution history
- `router_state` — KV store for router
- `sessions` — group → session_id mapping

**Нові таблиці для Canonical Store:**

```sql
-- Skills registry (from TZ-0.1, instantiated here)
CREATE TABLE IF NOT EXISTS skills (
  id TEXT PRIMARY KEY,                -- domain/subdomain/name (e.g. marketing/content/copywriter)
  name TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0.0',
  domain TEXT NOT NULL,               -- marketing | dev-ops | visual | data | communication | meta
  subdomain TEXT,                     -- content | analytics | etc.
  type TEXT NOT NULL,                 -- agent | skill | connector | command | module | process
  task_type TEXT,                     -- analytical | generative | transformational | orchestration
  model_tier TEXT DEFAULT 'sonnet',   -- opus | sonnet | haiku
  status TEXT DEFAULT 'active',       -- active | draft | deprecated
  file_path TEXT NOT NULL,            -- relative path to SKILL.md
  context_deps TEXT,                  -- JSON array: ["product/spec", "audience/icp"]
  triggers TEXT,                      -- JSON array: ["write article", "create content"]
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_skills_domain ON skills(domain);
CREATE INDEX IF NOT EXISTS idx_skills_type ON skills(type);

-- Service registry (which components are active)
CREATE TABLE IF NOT EXISTS services (
  id TEXT PRIMARY KEY,                -- unique service identifier
  type TEXT NOT NULL,                 -- 'channel' | 'connector' | 'scheduler' | 'ipc'
  name TEXT NOT NULL,                 -- human-readable name
  status TEXT DEFAULT 'active',       -- 'active' | 'stopped' | 'error'
  config TEXT,                        -- JSON config
  last_heartbeat TEXT,
  error_message TEXT,
  created_at TEXT NOT NULL
);

-- Schema version tracking (proper migrations)
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL,
  description TEXT
);
```

#### D. Runtime Mapping (mapping.yaml)

```yaml
# runtime/nanoclaw/mapping.yaml
runtime: nanoclaw
version: "1.0.0"

paths:
  foundation: /workspace/foundation/
  skills: /workspace/skills/
  context: /workspace/context/          # per-group, mounted from companies/{folder}/context/
  memory: /workspace/memory/            # per-group, mounted from companies/{folder}/memory/
  connectors: /workspace/connectors/

mount_strategy:
  foundation: readonly                  # shared across all containers
  skills: readonly                      # shared across all containers
  context: readonly                     # per-company, from canonical store
  memory: readwrite                     # per-company, agent writes here
  connectors: readonly                  # MCP configs
```

#### E. Migration System

```typescript
// src/migrations.ts
interface Migration {
  version: number;
  description: string;
  up: (db: Database) => void;
}

const migrations: Migration[] = [
  {
    version: 1,
    description: 'NanoClaw OS initial schema extensions',
    up: (db) => {
      // TZ-1.1 columns
      db.exec(`ALTER TABLE registered_groups ADD COLUMN group_type TEXT DEFAULT 'isolated'`);
      db.exec(`ALTER TABLE registered_groups ADD COLUMN parent_folder TEXT`);
      db.exec(`ALTER TABLE registered_groups ADD COLUMN context_inheritance TEXT`);
      db.exec(`ALTER TABLE registered_groups ADD COLUMN status TEXT DEFAULT 'active'`);
      db.exec(`ALTER TABLE registered_groups ADD COLUMN owner_user_id TEXT`);
      // TZ-1.2 tables
      db.exec(`CREATE TABLE IF NOT EXISTS skills (...)`);
      db.exec(`CREATE TABLE IF NOT EXISTS services (...)`);
      db.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (...)`);
    }
  }
];

export function runMigrations(db: Database): void {
  // Get current version
  // Apply pending migrations in order
  // Record each migration in schema_migrations
}
```

### 2.2 Excluded (DEFER)

- **Vector storage** for memory (future: Phase 4)
- **Distributed SQLite** (single-node only for MVP)
- **Auto-sync canonical store → runtime** (manual `sync.sh` for MVP)
- **Claude.ai / Cowork mapping** (NanoClaw mapping only for MVP)
- **Schema versioning UI** — migrations run automatically at startup

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] 4-layer separation documented and enforced (skills don't import runtime)
- [ ] Canonical store file structure created (foundation/, skills/, companies/, connectors/)
- [ ] `skills` table created with full schema
- [ ] `services` table created
- [ ] `schema_migrations` table + migration runner
- [ ] `mapping.yaml` for NanoClaw runtime
- [ ] Backward-compatible with existing NanoClaw v1.1.3 database

### P1 — Full MVP

- [ ] `runMigrations()` function with versioned migrations
- [ ] Service registry: register/deregister/heartbeat
- [ ] Canonical store initialization script (`scripts/init-canonical-store.sh`)
- [ ] Foundation files scaffolded from TZ-0.* outputs

### P2 — Extended

- [ ] `sync.sh` for canonical store → runtime mount refresh
- [ ] mapping.yaml for claude-code and claude-ai runtimes
- [ ] Schema migration rollback support

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/db.ts` | MODIFY | Add skills, services, schema_migrations tables |
| `src/migrations.ts` | CREATE | Migration runner with versioned migrations |
| `src/services.ts` | CREATE | Service registry CRUD |
| `scripts/init-canonical-store.sh` | CREATE | Scaffold canonical store structure |
| `runtime/nanoclaw/mapping.yaml` | CREATE | Path mapping config |
| `foundation/` | CREATE | Layer 1 scaffolding |
| `companies/` | CREATE | Layer 2 template |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `src/db.ts` | 12-81 | Existing schema + migration pattern (try/catch ALTER TABLE) |
| `src/types.ts` | 1-105 | All existing interfaces |
| `src/config.ts` | — | DATA_DIR, STORE_DIR, GROUPS_DIR constants |
| `docs/architecture/phase-1-topology.md` | 131-190 | 4-layer diagram |
| `docs/architecture/phase-1-topology.md` | 194-363 | Canonical store structure |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| better-sqlite3 schema | NanoClaw v1.1.3 `db.ts` | COPY | Base + extensions |
| try/catch ALTER TABLE | NanoClaw v1.1.3 `db.ts` L82-119 | ADAPT | Replace with migration runner |
| ContainerConfig mount | NanoClaw v1.1.3 `types.ts` | ADAPT | Add canonical store mounts |
| Plugin structure | Anthropic knowledge-work plugins | ADAPT | Skills folder layout |
| SQLite migration pattern | Standard Node.js | BUILD | Versioned migration runner |

### Risks

1. **Migration ordering** — TZ-1.1 and TZ-1.2 migrations must be in correct order (1.1 first)
2. **Container mount complexity** — Foundation + skills (shared) vs context + memory (per-group) = different mount strategies
3. **Git as canonical store** — Large binary files (images, videos) should NOT be in git. Use `.gitignore` + external storage reference.

---

## 5. Testing

### Unit Tests

```typescript
describe('Schema migrations', () => {
  test('fresh database gets all tables');
  test('existing v1.1.3 database migrates safely');
  test('migration version tracking works');
  test('duplicate migration skipped');
});

describe('Skills registry', () => {
  test('registerSkill stores correct data');
  test('getSkillsByDomain returns filtered results');
  test('updateSkill version increments');
});

describe('Service registry', () => {
  test('registerService + heartbeat');
  test('deregisterService removes entry');
  test('stale service detected (no heartbeat > 5min)');
});
```

### Integration Tests

```typescript
describe('Canonical store initialization', () => {
  test('init-canonical-store.sh creates full structure');
  test('mapping.yaml paths resolve correctly');
  test('layer separation: skills/ has no runtime imports');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Migration runner tested on empty DB + existing v1.1.3 DB
- [ ] Skills table schema matches TZ-0.1 specification
- [ ] Canonical store structure documented and scaffolded
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors
