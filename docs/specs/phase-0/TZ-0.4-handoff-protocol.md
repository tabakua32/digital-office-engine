# TZ-0.4: Handoff Protocol

> **Phase**: 0 — Foundation Layer
> **Priority**: P1
> **Sessions**: 1-2
> **Dependencies**: TZ-0.1 (Skill Standard — defines agent types)
> **Verdict**: BUILD 60% | ADAPT 30% | COPY 10%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.6

---

## 1. Мета

Визначити формальний JSON-контракт для комунікації між агентами
(Agent → Agent, Agent → Skill, Skill → Agent). Включає cascade check
(перевірка upstream confidence), tone isolation (очистка тону при передачі),
та error escalation (що робити при помилці).

**Без цього ТЗ**: агенти передають неструктуровані тексти →
каскадна деградація → Agent#7 будує на помилках Agent#3 →
користувач отримує сміття.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Handoff JSON Schema

```json
{
  "handoff_id": "uuid-v4",
  "timestamp": "ISO-8601",
  "thread_id": 43,
  "from": {
    "agent": "mi-analyst",
    "domain": "marketing",
    "function": "skill",
    "task_type": "analytical"
  },
  "to": {
    "agent": "positioning-strategist",
    "domain": "marketing",
    "function": "agent",
    "task_type": "analytical"
  },
  "payload": {
    "format": "markdown | json | csv | structured",
    "content": "...",
    "metadata": {
      "confidence": 0.85,
      "evidence_grade": "IV",
      "sources_count": 7,
      "data_freshness": "2026-02-28",
      "gaps": ["pricing data incomplete"],
      "assumptions": ["market size based on 2025 report"]
    }
  },
  "constraints": {
    "tone_isolation": true,
    "cascade_check": true,
    "max_context_tokens": 4000,
    "required_output_format": "positioning_statement"
  },
  "error": {
    "on_low_confidence": "flag_and_continue | retry | escalate",
    "on_format_mismatch": "adapt | reject | escalate",
    "on_timeout": "partial_result | escalate"
  }
}
```

#### B. Cascade Check Protocol

Upstream confidence determines action:

| Confidence | Action | UI Signal |
|-----------|--------|-----------|
| 0.8+ | Proceed normally | — |
| 0.5-0.8 | Flag uncertainty in output | ⚠️ Low confidence |
| 0.3-0.5 | Request human review (HITL Flow E) | 🔶 Needs review |
| <0.3 | REJECT and escalate to owner | 🔴 Rejected |

**Implementation**: Receiving agent MUST check `payload.metadata.confidence`
BEFORE processing. If cascade_check=true and confidence < threshold,
follow the error handling rules.

#### C. Tone Isolation Protocol

When handoff crosses task types (e.g., generative → analytical):

1. **Strip tone markers** — remove emotional language, marketing copy style
2. **Extract factual claims** — keep only data, numbers, citations
3. **Apply own tone** — from receiving agent's SKILL.md identity section
4. **Warmth-Accuracy Tradeoff** — analytical tasks = COLD tone
   (Apart Research 2025: warm tone → +10-30% more errors)

#### D. NanoClaw IPC Implementation

```
Container A writes: /ipc/handoffs/[handoff_id].json
Container B reads:  /ipc/handoffs/[handoff_id].json
Container B validates → processes → writes response
Response:           /ipc/handoffs/[handoff_id]-response.json
```

#### E. Evidence Grading System

Each handoff payload carries evidence_grade (from Marketing Chain v3):

| Grade | Name | Definition |
|-------|------|------------|
| NOBEL | Gold standard | Peer-reviewed research, official statistics |
| PR | Peer reviewed | Published research, industry reports |
| IV | Industry validated | Case studies, benchmark data |
| PP | Professional practice | Expert opinion, best practices |
| HEUR | Heuristic | Pattern recognition, educated guess |
| DISC | Discovery | Exploratory, no validation yet |

### 2.2 Excluded

- HITL flow implementation (= TZ-4.2 Extended Flows)
- IPC protocol implementation (= existing NanoClaw + TZ-2.5.4)
- Multi-agent pipeline orchestration (= TZ-0.6 Process Templates)
- Actual agent-to-agent routing logic (= TZ-1.3 Core Flows)

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] Handoff JSON Schema documented with TypeScript interface
- [ ] Cascade check protocol: 4 confidence levels with actions
- [ ] Tone isolation: rules for cross-task-type handoffs
- [ ] Evidence grading: 6 grades defined with examples
- [ ] IPC file path convention documented
- [ ] Error handling: 3 error types × 3 strategies = 9 scenarios defined
- [ ] Example handoff created: MI Analyst → Positioning Strategist

### Should Pass (P1)

- [ ] TypeScript types exported (`HandoffSchema`, `CascadeCheck`, `EvidenceGrade`)
- [ ] Validation function: `validateHandoff(json) → errors[]`
- [ ] Handoff logger: records all handoffs to SQLite for debugging

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── docs/standards/
│   └── handoff-protocol.md         ← Full protocol document
├── src/types/
│   └── handoff.ts                  ← TypeScript interfaces
├── src/utils/
│   └── validate-handoff.ts         ← Validation function
└── templates/
    └── handoff-example.json        ← Reference handoff
```

### 4.2 TypeScript Interface

```typescript
interface HandoffPayload {
  handoff_id: string;
  timestamp: string;
  thread_id?: number;
  from: AgentIdentity;
  to: AgentIdentity;
  payload: {
    format: 'markdown' | 'json' | 'csv' | 'structured';
    content: string;
    metadata: HandoffMetadata;
  };
  constraints: HandoffConstraints;
  error: ErrorHandling;
}

interface HandoffMetadata {
  confidence: number;        // 0.0 - 1.0
  evidence_grade: 'NOBEL' | 'PR' | 'IV' | 'PP' | 'HEUR' | 'DISC';
  sources_count: number;
  data_freshness: string;    // ISO date
  gaps: string[];
  assumptions: string[];
}
```

### 4.3 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| Architecture §0.6 | `docs/architecture/phase-0-foundation.md` L558-646 | Full protocol spec |
| NanoClaw IPC | `src/ipc.ts` | Existing IPC file patterns |
| Phase 4 Flow C | `docs/architecture/phase-4-information-flows.md` | Agent→Agent flow design |
| Apart Research 2025 | Referenced in architecture | Warmth-accuracy tradeoff data |

---

## 5. Testing

```bash
# Validate example handoff against schema
npx ts-node src/utils/validate-handoff.ts templates/handoff-example.json

# Test cascade check with different confidence levels
npx vitest run tests/handoff/cascade-check.test.ts

# Test tone isolation (mock: generative → analytical)
npx vitest run tests/handoff/tone-isolation.test.ts
```

---

## 6. Definition of Done

- [ ] Protocol document complete
- [ ] TypeScript types exported
- [ ] Validation function works
- [ ] Example handoff validates
- [ ] SPEC-INDEX.md updated: TZ-0.4 = DONE

---

_Cross-references: TZ-0.1 (agent types), TZ-0.5 (output format that handoff carries), TZ-1.3 (routing uses handoff), TZ-4.1 (flows use handoff)_
