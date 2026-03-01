# TZ-1.5: Extended Flows + Session Transfer

> **Phase**: 1 — General System Topology
> **Priority**: P2 (розширення після базових потоків)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.3 (core flows A-D)
> **Verdict**: BUILD 40% | ADAPT 30% | DEFER 30%
> **Architecture ref**: `docs/architecture/phase-1-topology.md` §1.6 (Flows E-F)

---

## 1. Мета

Визначити розширені інформаційні потоки (E-G) які доповнюють базові (A-D):
HITL approval loops, background async tasks, та session transfer між runtime'ами
(NanoClaw → Claude.ai, NanoClaw → Claude Code). Ці потоки перетворюють систему
з reactive (повідомлення → відповідь) на proactive (планування, перевірка, делегування).

**Без цього ТЗ**: агент не може попросити підтвердження людини перед критичною дією,
не може виконувати фонові задачі які тривають годинами, не може передати сесію
в Claude.ai для глибокого аналізу.

---

## 2. Scope

### 2.1 Included (MVP)

#### Flow E: HITL (Human-in-the-Loop)

```
Agent executing skill detects critical decision:
│
├── 1. Agent writes HITL request to IPC:
│      /ipc/{group}/hitl/{request_id}.json
│      {
│        type: "hitl_request",
│        request_id: "hitl-xxxx",
│        skill: "marketing/content/copywriter",
│        question: "Публікувати цей пост зараз чи запланувати на 9:00?",
│        options: [
│          { id: "now", label: "Зараз", description: "Опублікувати негайно" },
│          { id: "schedule", label: "О 9:00", description: "Запланувати на завтра 9:00" },
│          { id: "edit", label: "Редагувати", description: "Повернути на редагування" }
│        ],
│        timeout_minutes: 60,
│        default_action: "schedule",    // if timeout → do this
│        context: { draft_text: "...", channel: "..." }
│      }
│
├── 2. Host IPC watcher reads HITL request
│      → Build inline keyboard from options
│      → Send to user via Telegram:
│        "🔔 Потрібне ваше рішення:
│         Публікувати цей пост зараз чи запланувати?
│         [Зараз] [О 9:00] [Редагувати]
│         ⏰ Автоматично: О 9:00 через 60 хв"
│
├── 3. User clicks button → callback_data = "hitl:hitl-xxxx:schedule"
│      → Write response to IPC:
│        /ipc/{group}/hitl-responses/{request_id}.json
│        { request_id, chosen: "schedule", user_id, timestamp }
│
├── 4. Agent container polls hitl-responses/
│      → Read response → continue execution
│      → OR: timeout → execute default_action
│
└── 5. Cleanup: delete request + response files
```

**HITL TypeScript interfaces:**

```typescript
interface HitlRequest {
  type: 'hitl_request';
  request_id: string;
  skill: string;
  question: string;
  options: HitlOption[];
  timeout_minutes: number;
  default_action: string;          // option id
  context?: Record<string, unknown>;
  created_at: string;
}

interface HitlOption {
  id: string;
  label: string;                   // button text (max 20 chars)
  description?: string;
}

interface HitlResponse {
  request_id: string;
  chosen: string;                  // option id
  user_id: string;
  timestamp: string;
}
```

**Standard HITL layouts:**

| Layout | Options | Use Case |
|--------|---------|----------|
| approve_reject | ✅ Approve / ❌ Reject | Content review, publish |
| schedule_choice | Now / Time A / Time B / Custom | Publishing timing |
| quality_gate | Pass / Fix Minor / Rework / Reject | Skill evaluation |
| budget_confirm | Proceed / Adjust / Cancel | Paid actions (ads, API calls) |

#### Flow F: Background Tasks (Async)

```
Agent needs to run long operation (>5min):
│
├── 1. Agent writes background_task to IPC:
│      /ipc/{group}/background/{task_id}.json
│      {
│        type: "background_task",
│        task_id: "bg-xxxx",
│        skill: "marketing/analytics/reporter",
│        prompt: "Зроби повний аудит конкурентів за останній місяць",
│        estimated_minutes: 30,
│        notify_on_complete: true,
│        notify_thread_id: 42,          // thread to post result
│        priority: "low"                 // low | normal | high
│      }
│
├── 2. Host IPC watcher reads task
│      → Creates scheduled_task (schedule_type='once', next_run=now)
│      → Sends notification: "⏳ Задачу прийнято. Орієнтовний час: 30 хв"
│
├── 3. Task scheduler picks up task
│      → Spawns dedicated container
│      → Runs skill with extended timeout
│      → Saves result to task_run_logs
│
├── 4. On completion:
│      → Send result to notify_thread_id
│      → "✅ Аудит конкурентів завершено: [summary]"
│      → Write result file: /ipc/{group}/results/{task_id}.json
│
└── 5. Original agent can read result if still running
       (or user gets notification)
```

#### Flow G: Session Transfer (Cross-Runtime)

```
User: "/export-session" in NanoClaw:
│
├── 1. Collect session state:
│      ├── CLAUDE.md (current identity + state)
│      ├── Recent messages (last N from SQLite)
│      ├── Active handoffs (pending)
│      ├── Context modules (5 categories)
│      └── Memory (facts.jsonl + decisions.jsonl)
│
├── 2. Generate session_transfer.md:
│      """
│      # Session Transfer: {group_name}
│      ## Transfer ID: {uuid}
│      ## Created: {timestamp}
│      ## Source Runtime: NanoClaw v{version}
│      
│      ## Identity
│      {CLAUDE.md content}
│      
│      ## Current Task
│      {last N messages + current skill state}
│      
│      ## Context Snapshot
│      {inline all context modules}
│      
│      ## Instructions for Target Runtime
│      Continue from step {N}. Key context above.
│      Respond in Ukrainian. Use evidence grades.
│      """
│
├── 3. Deliver to target:
│      ├── Claude.ai: upload as Project Knowledge file
│      ├── Claude Code: save to .claude/ project
│      └── Manual: download as .md file
│
└── 4. Track transfer in SQLite:
       session_transfers(id, source_runtime, target_runtime, status, created_at)
```

**Session transfer SQLite:**

```sql
CREATE TABLE IF NOT EXISTS session_transfers (
  id TEXT PRIMARY KEY,
  group_folder TEXT NOT NULL,
  source_runtime TEXT NOT NULL,        -- 'nanoclaw' | 'claude-code' | 'claude-ai'
  target_runtime TEXT,
  content_hash TEXT,                   -- SHA-256 for integrity
  status TEXT DEFAULT 'created',       -- 'created' | 'delivered' | 'resumed' | 'expired'
  created_at TEXT NOT NULL,
  expires_at TEXT,
  FOREIGN KEY (group_folder) REFERENCES registered_groups(folder)
);
```

### 2.2 Excluded (DEFER)

- **HITL with media** (photo/document approval) — Phase 2
- **HITL multi-step wizards** (sequential approval chains) — Phase 2.3
- **Background task queue** with priority scheduling — Phase 4
- **Auto-import session** from Claude.ai → NanoClaw — Phase 4
- **Real-time sync** between runtimes — future (WebSocket)
- **Cowork integration** — low priority, evaluate later

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] HITL request → inline keyboard → user response → agent continues
- [ ] HITL timeout → default action executed
- [ ] IPC directories: hitl/, hitl-responses/, background/, results/
- [ ] Standard HITL layouts defined (4 layouts)

### P1 — Full MVP

- [ ] Background task flow: agent → IPC → scheduler → notify
- [ ] /export-session command generates session_transfer.md
- [ ] session_transfers SQLite table
- [ ] Background task estimated time displayed to user

### P2 — Extended

- [ ] Session transfer to Claude.ai (upload via MCP/Google Drive)
- [ ] Transfer integrity check (SHA-256 hash)
- [ ] Transfer expiry (auto-expire after 72h)
- [ ] HITL analytics: avg response time, timeout rate

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/ipc.ts` | MODIFY | Add hitl + background + results processing |
| `src/flows/hitl.ts` | CREATE | HITL request/response pipeline |
| `src/flows/background.ts` | CREATE | Background task handling |
| `src/flows/session-transfer.ts` | CREATE | Export/import session state |
| `src/commands/export-session.ts` | CREATE | /export-session command |
| `src/db.ts` | MODIFY | Add session_transfers table |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `src/ipc.ts` | 34-153 | Existing IPC watcher pattern |
| `src/task-scheduler.ts` | — | Scheduler for background tasks |
| `src/channels/telegram.ts` | — | Inline keyboard creation |
| `docs/architecture/phase-1-topology.md` | 408-447 | Flows D-F |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| IPC file-based protocol | NanoClaw v1.1.3 `ipc.ts` | ADAPT | Add hitl + background dirs |
| ask-user.ts HITL | linuz90/claude-code-telegram | ADAPT | Inline keyboard HITL flow |
| Callback routing | Angusstone7/claude-code-telegram | ADAPT | callback_data parsing |
| Task scheduler | NanoClaw v1.1.3 `task-scheduler.ts` | ADAPT | Background task execution |
| Session export | — | BUILD | No existing reference |

### Risks

1. **HITL race condition** — Agent container may exit before user responds. Solution: persist request, re-spawn agent with response on next poll.
2. **Background task resource usage** — Multiple background tasks = multiple containers. Solution: max concurrent limit (configurable).
3. **Session transfer size** — Full context + messages can exceed file limits. Solution: compress, truncate old messages, reference external files.

---

## 5. Testing

### Unit Tests

```typescript
describe('Flow E: HITL', () => {
  test('HITL request written to correct IPC directory');
  test('inline keyboard built from options');
  test('callback_data parsed → response written');
  test('timeout triggers default action');
  test('expired HITL request cleaned up');
});

describe('Flow F: Background', () => {
  test('background task created as once-type scheduled task');
  test('completion notification sent to correct thread');
  test('result file written to results/ directory');
});

describe('Flow G: Session Transfer', () => {
  test('session_transfer.md contains all required sections');
  test('transfer recorded in SQLite');
  test('transfer hash matches content');
  test('expired transfer not resumable');
});
```

### Integration Tests

```typescript
describe('Extended flows integration', () => {
  test('skill triggers HITL → user approves → skill continues');
  test('skill spawns background task → completes → notifies');
  test('export-session → file generated → importable');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] HITL flow tested with Telegram inline keyboards
- [ ] Background task integrates with existing scheduler
- [ ] Session transfer generates valid standalone .md
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors
