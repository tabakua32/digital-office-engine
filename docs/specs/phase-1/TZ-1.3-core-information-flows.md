# TZ-1.3: Core Information Flows

> **Phase**: 1 — General System Topology
> **Priority**: P0 (без потоків даних система мертва)
> **Sessions**: 2-3
> **Dependencies**: TZ-1.2 (canonical store, layer separation)
> **Verdict**: ADAPT 55% | COPY 15% | BUILD 30%
> **Architecture ref**: `docs/architecture/phase-1-topology.md` §1.6

---

## 1. Мета

Визначити та формалізувати 4 базові інформаційні потоки (A-D) які забезпечують
роботу NanoClaw OS в реальному часі: від отримання повідомлення до відповіді
користувачу. Кожен потік описується як pipeline з чіткими етапами, відповідальними
компонентами та точками розширення.

**Без цього ТЗ**: повідомлення губляться між компонентами, routing працює ad-hoc,
streaming виводу не стандартизований, помилки не обробляються — blackbox замість pipeline.

---

## 2. Scope

### 2.1 Included (MVP)

#### Flow A: INBOUND (Human → System)

```
 User (Telegram/WhatsApp)
    │
    ├─── text / voice / photo / document / callback / location / payment
    │
    ▼
 Channel Adapter (telegram.ts / whatsapp.ts)
    │
    ├── 1. Parse message → NewMessage { id, chat_jid, sender, content, timestamp }
    ├── 2. storeChatMetadata() → update chats table
    ├── 3. storeMessage() → save to messages table (registered groups only)
    ├── 4. Emit onInboundMessage callback
    │
    ▼
 Message Loop (index.ts → startMessageLoop)
    │
    ├── 5. Poll: getNewMessages() every POLL_INTERVAL (2s)
    ├── 6. For each message: find registered group by chat_jid
    ├── 7. Trigger check: TRIGGER_PATTERN.test(content) — non-main groups only
    ├── 8. Queue: GroupQueue.enqueue(chatJid, processGroupMessages)
    │
    ▼
 Group Processor (processGroupMessages)
    │
    ├── 9. getMessagesSince(chatJid, lastAgentTimestamp)
    ├── 10. formatMessages() → XML format for Claude
    ├── 11. Advance cursor (lastAgentTimestamp), save to router_state
    ├── 12. setTyping(chatJid, true)
    │
    ▼
 Container Runner (runContainerAgent)
    │
    ├── 13. Mount: group folder + foundation + skills + connectors
    ├── 14. Spawn container (Docker/Apple Container)
    ├── 15. Send prompt via stdin
    ├── 16. Stream results via stdout → onOutput callback
    │
    ▼
 Claude Agent SDK (inside container)
    │
    ├── 17. Read CLAUDE.md + context modules (Layer 2)
    ├── 18. Select skill based on trigger/routing
    ├── 19. Execute skill with prompt
    ├── 20. Generate response (streaming)
    └── 21. Write to stdout → IPC messages/tasks (optional)
```

**Key existing code (COPY):**
- `src/index.ts` L126-215: `processGroupMessages()` — main inbound pipeline
- `src/index.ts` L296+: `startMessageLoop()` — polling loop
- `src/router.ts` L12-17: `formatMessages()` — XML message formatting
- `src/group-queue.ts`: concurrency control per group

**NanoClaw OS extensions (ADAPT/BUILD):**
- Skill-based routing instead of single-agent (BUILD)
- Context module injection per skill (BUILD)
- Multi-format input handling: voice STT, photo OCR, document extraction (Phase 2)

#### Flow B: OUTBOUND (System → Human)

```
 Agent Runner (container stdout)
    │
    ├── Streaming output (NDJSON lines)
    │   { result: "text", newSessionId: "..." }
    │
    ▼
 Output Callback (index.ts → wrappedOnOutput)
    │
    ├── 1. Track session ID updates
    ├── 2. Strip <internal>...</internal> tags
    ├── 3. Find channel by chatJid → channel.sendMessage()
    │
    ▼
 Channel Adapter (telegram.ts → sendMessage)
    │
    ├── 4. Apply channel adaptor rules (from TZ-0.5):
    │   ├── Chunk text if > 4096 chars (Telegram limit)
    │   ├── Convert Markdown → MarkdownV2
    │   ├── Handle media attachments
    │   └── Add inline keyboards (if HITL)
    ├── 5. Send via Bot API / WhatsApp
    ├── 6. Store bot message (is_bot_message = 1)
    └── 7. setTyping(chatJid, false)
```

**Key existing code (COPY):**
- `src/index.ts` L177-195: streaming output callback
- `src/router.ts` L19-27: `formatOutbound()` — strip internal tags
- `src/router.ts` L29-37: `routeOutbound()` — channel routing
- `src/channels/telegram.ts`: sendMessage implementation

**NanoClaw OS extensions (ADAPT/BUILD):**
- Output template application per task_type (from TZ-0.5)
- Channel adaptor engine (TZ-2.2 scope)
- Multi-chunk streaming with edit-in-place (Phase 2)

#### Flow C: AGENT → AGENT (Handoff)

```
 Agent A (in container)
    │
    ├── Intra-session handoff (same container):
    │   Agent A → call sub-skill → get result → continue
    │   No IPC needed, in-process.
    │
    ├── Inter-session handoff (different containers):
    │   Agent A writes handoff.json:
    │   {
    │     from: "marketing/content/copywriter",
    │     to: "marketing/content/editor",
    │     payload: { content, confidence, evidence_grade, gaps },
    │     constraints: { tone_isolation, max_tokens, requires_hitl },
    │     metadata: { created_at, ttl_hours, chain_id, step }
    │   }
    │
    │   → IPC file: /ipc/{group}/handoffs/{id}.json
    │   → Host reads, spawns Agent B container
    │   → Agent B reads handoff, executes, writes result
    │
    └── Cross-platform handoff:
        Agent A → session_transfer.md → Git push → Agent B in Claude.ai
        (DEFER to TZ-1.5)
```

**Handoff protocol** (from TZ-0.4):

```typescript
interface HandoffPayload {
  from: string;              // skill ID (domain/subdomain/name)
  to: string;                // target skill ID
  payload: {
    content: string;         // main content to pass
    confidence: number;      // 0.0-1.0
    evidence_grade: string;  // NOBEL | PR | IV | PP | HEUR | DISC
    gaps: string[];          // what's missing
  };
  constraints: {
    tone_isolation: boolean; // strip source tone, apply target's
    max_tokens?: number;
    requires_hitl: boolean;  // needs human approval
  };
  metadata: {
    created_at: string;
    ttl_hours: number;
    chain_id: string;        // traces the full chain
    step: number;
  };
}
```

**NanoClaw OS implementation:**
- IPC handoff directory: `data/ipc/{group}/handoffs/`
- Host IPC watcher processes handoff files (extend `ipc.ts`)
- Cascade check: 0.8+ proceed, 0.5-0.8 flag, <0.5 HITL

#### Flow D: SCHEDULED (System → System → Human)

```
 Task Scheduler (task-scheduler.ts)
    │
    ├── Poll every 60s: getDueTasks()
    ├── For each due task:
    │   ├── Resolve group_folder → RegisteredGroup
    │   ├── runContainerAgent(group, task.prompt, task.chat_jid)
    │   ├── updateTaskAfterRun(id, nextRun, result)
    │   └── logTaskRun(taskId, duration, status)
    │
    └── Schedule types:
        ├── cron: "0 9 * * 1" (кожен понеділок о 9)
        ├── interval: 86400000 (кожні 24 години)
        └── once: "2026-03-15T10:00:00Z" (одноразово)
```

**Key existing code (COPY):**
- `src/task-scheduler.ts`: full scheduler loop
- `src/db.ts` L334-465: task CRUD operations
- `src/ipc.ts` L180-270: schedule_task IPC handler

**NanoClaw OS extensions (ADAPT):**
- Context mode: `isolated` (task-only context) vs `group` (full group context)
- Skill-based task routing: task → skill → execute
- Task result notification preferences (which chat to notify)

### 2.2 Excluded (DEFER → TZ-1.5, TZ-4.*)

- **Flow E**: HITL (human approval loops) — TZ-1.5
- **Flow F**: Background (async, non-blocking tasks) — TZ-1.5
- **Flow G**: Session Transfer (between runtimes) — TZ-1.5
- **Flow H**: Context Update (extraction, sync) — TZ-4.*
- **Flow I**: Escalation (error → human) — TZ-4.*
- **Flow J**: Analytics/Audit (logging, metrics) — TZ-4.*

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Flow A (Inbound) pipeline documented with exact code references
- [ ] Flow B (Outbound) pipeline documented with channel adaptor points
- [ ] Flow C (Handoff) IPC directory structure + JSON schema defined
- [ ] Flow D (Scheduled) existing scheduler preserved, extensions defined
- [ ] All 4 flows have error handling defined (retry, rollback, escalation)
- [ ] Cursor management (lastAgentTimestamp) documented and tested

### P1 — Full MVP

- [ ] Handoff IPC watcher added to `ipc.ts` (process handoff files)
- [ ] Cascade confidence check implemented
- [ ] Skill-based routing: message → detect intent → route to skill
- [ ] Output template application in outbound flow

### P2 — Extended

- [ ] Flow metrics: latency per stage, error rate tracking
- [ ] Flow visualization (Mermaid diagrams) auto-generated
- [ ] Multi-channel outbound: same message to TG + email

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/ipc.ts` | MODIFY | Add handoff file processing to IPC watcher |
| `src/router.ts` | MODIFY | Add skill routing logic |
| `src/flows/inbound.ts` | CREATE | Refactored inbound pipeline as module |
| `src/flows/outbound.ts` | CREATE | Refactored outbound pipeline as module |
| `src/flows/handoff.ts` | CREATE | Handoff processing + cascade check |
| `src/flows/types.ts` | CREATE | HandoffPayload, FlowMetrics interfaces |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `src/index.ts` | 126-294 | processGroupMessages + runAgent — full inbound/outbound |
| `src/index.ts` | 296-350 | startMessageLoop — polling pipeline |
| `src/router.ts` | 1-45 | Message formatting + outbound routing |
| `src/ipc.ts` | 34-153 | IPC watcher (messages + tasks processing) |
| `src/task-scheduler.ts` | — | Full scheduler implementation |
| `src/group-queue.ts` | — | Concurrency control per group |
| `docs/architecture/phase-1-topology.md` | 367-447 | 6 information flows |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| Message polling loop | NanoClaw v1.1.3 `index.ts` | COPY | Base inbound pipeline |
| Streaming output callback | NanoClaw v1.1.3 `index.ts` | COPY | Base outbound pipeline |
| IPC file-based protocol | NanoClaw v1.1.3 `ipc.ts` | ADAPT | Add handoff files |
| XML message format | NanoClaw v1.1.3 `router.ts` | COPY | Claude input format |
| Task scheduler | NanoClaw v1.1.3 `task-scheduler.ts` | COPY | Cron/interval/once |
| Cursor rollback on error | NanoClaw v1.1.3 `index.ts` L200-211 | COPY | Reliable message processing |
| Handoff JSON | Architecture §1.6 Flow C | BUILD | New inter-agent protocol |

### Risks

1. **Skill routing complexity** — Message intent detection → skill mapping may need Claude call (latency + cost). Start with explicit triggers (/command), add NLU later.
2. **Handoff timeout** — If Agent B never processes handoff, data stays in IPC forever. Solution: TTL + cleanup job.
3. **Cursor rollback race** — If output was sent to user but error happens later, rollback sends duplicates. Current code handles this (L200-205).

---

## 5. Testing

### Unit Tests

```typescript
describe('Flow A: Inbound', () => {
  test('message stored and queued for processing');
  test('trigger check for non-main groups');
  test('cursor advances after successful processing');
  test('cursor rolls back on error (no output sent)');
  test('cursor NOT rolled back if output already sent');
});

describe('Flow B: Outbound', () => {
  test('internal tags stripped from output');
  test('message routed to correct channel');
  test('typing indicator set/cleared');
  test('session ID tracked from output');
});

describe('Flow C: Handoff', () => {
  test('handoff JSON written to correct IPC directory');
  test('handoff processed by IPC watcher');
  test('cascade check: high confidence → auto proceed');
  test('cascade check: low confidence → HITL flag');
  test('expired handoff (TTL) cleaned up');
});

describe('Flow D: Scheduled', () => {
  test('due tasks executed on time');
  test('cron expression parsed correctly');
  test('task result logged and next_run updated');
  test('failed task logged with error');
});
```

### Integration Tests

```typescript
describe('End-to-end flows', () => {
  test('inbound message → process → outbound response');
  test('scheduled task → execute → notify user');
  test('handoff: skill A → IPC → skill B → result');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] 4 flow diagrams (ASCII) в документації
- [ ] Handoff IPC directory + JSON schema implemented
- [ ] No regression in existing 436 tests
- [ ] TypeScript compiles without errors
- [ ] Error handling documented for each flow stage
