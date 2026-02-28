# NanoClaw OS — Architecture Reference
**Date**: 2026-02-28 | **Version**: v4 | **Purpose**: onboard next chat session

---

## 0. NAVIGATION

### Architecture Phases

| Phase | File | Status | Scope |
|---|---|---|---|
| **Phase 0** | [phase-0-foundation.md](./phase-0-foundation.md) | DONE | Foundation: Skill Standard, Taxonomy, Evaluation, Handoff, Templates |
| **Phase 1** | [phase-1-topology.md](./phase-1-topology.md) | DONE | Topology: 4 layers, ownership, canonical store, 6x6 matrix, 14 principles |
| **Phase 2** | [phase-2-telegram.md](./phase-2-telegram.md) | DONE | Telegram Bot API 9.3: full map, streaming, HITL, forums, Mini Apps |
| **Phase 2.5** | [phase-2.5-mtproto.md](./phase-2.5-mtproto.md) | DONE | MTProto Userbot: GramJS, dual-channel, 61 capabilities, anti-ban |
| **Phase 3** | [phase-3-claude-platform.md](./phase-3-claude-platform.md) | DONE | Claude Platform: API map, Model Matrix, MCP, Caching, Batch, Cost |
| **Phase 4** | [phase-4-information-flows.md](./phase-4-information-flows.md) | DONE | Information Flows (A-J): 10 flows, memory, HITL, channel adaptors |
| **Phase 5** | [phase-5-deployment.md](./phase-5-deployment.md) | DONE | Deployment: Docker, secrets, monitoring, security, scaling, roadmap |

Details: [CONTEXT_EXTENDED.md](./CONTEXT_EXTENDED.md) — methodology, gaps, research, reference docs.

---

## 1. WHAT IS BEING BUILT

**NanoClaw OS** — operating system for AI marketing department based on Claude Agent SDK.

**One sentence**: NanoClaw is a wrapper around Claude Agent SDK (Node.js/TypeScript) that receives Telegram messages, spawns isolated containers with Claude agents, gives them tools (MCP, bash, files), and returns results to chat.

**Business context**: Part of YaKomanda AI Academy — educational platform with AI courses for marketers ($490-990), target audience — freelancers and entrepreneurs ($500-5000/mo).

---

## 2. ARCHITECTURE SUMMARY

### Phase 0: Foundation Layer
- Unified Skill Standard: single format, token economics, sandwich structure
- Taxonomy Matrix: 6 domains x 6 functions (MECE)
- Evaluation Framework: 100-point scoring, signal-based quality
- Handoff Protocol: cascading verification, tone isolation
- Output + Process Templates: per task-type formatting

### Phase 1: General Topology
- 4 layers: Runtime → Foundation → Context Modules → Domain Skills
- Ownership: 1 instance = 1 owner = N companies (isolated containers)
- 14 architectural principles, 10 data flows (A-J)

### Phase 2: Telegram Platform Layer
- Bot API 9.3: messaging, keyboards, forums, channels, payments, Mini Apps
- sendMessageDraft (streaming), HITL 3 levels, Voice I/O pipeline
- Channel adaptor: 4096 chars, MarkdownV2, chunking

### Phase 2.5: MTProto Userbot Layer
- GramJS: 61 new capabilities (87% unique)
- Dual-channel: Bot (UI+HITL) + User (data+intelligence)
- Anti-ban: risk classification, rate limiting, HITL for HIGH risk

### Phase 3: Claude Platform Layer
- API: Messages, Extended Thinking, Caching, Batch, Compaction, Streaming, Tool Use
- Model Matrix: 6 tasks x 3 models (Opus/Sonnet/Haiku)
- MCP: 6 connectors + context budget, Prompt Caching 3-layer strategy
- Container lifecycle: 7-step, error cascade, cost optimization

### Phase 4: Information Flows & Memory
- 10 flows: User→Agent (A), Cross-Runtime (B), Handoff (C), Content Pipeline (D), HITL (E), Scheduled (F), Memory (G), Context Evolution (H), Batch (I), Cost Tracking (J)
- 3-level Memory: CLAUDE.md → facts.jsonl → decisions.jsonl
- 6 Channel Adaptors: telegram, linkedin, email, instagram, youtube, file_output

### Phase 5: Deployment & Security
- Docker: host (always-on) + ephemeral agents (256MB, 0.5CPU, 5min)
- Security: 22-item audit checklist, container isolation
- Scaling: S0 single → S1 power user → S2 multi-owner
- Roadmap Q1-Q4 2026

---

## 3. CRITICAL DECISIONS

| # | Decision | Summary |
|---|---|---|
| 3.1 | **Generate from scratch, don't adapt** | Methodology (52 blocks) more complex than GitHub skills |
| 3.2 | **3-layer architecture** | Foundation (build once) → Context (onboarding) → Domain Skills (factory) |
| 3.3 | **MECE matrix** | 6 domains x 6 functions = dynamic structure |
| 3.4 | **Bootstrap sequence** | Factory → Dev Team → Domain Skills |
| 3.5 | **Telegram-first, platform-agnostic** | Skills DON'T know about Telegram. Channel adaptor = last step |
| 3.6 | **Bot + User = full coverage** | Bot=UI+HITL, User=data+intelligence. User OPTIONAL |

---

## 4. THREE INDEPENDENT TRACKS

### TRACK A: Architecture — ALL DONE

```
Phase 0 → Phase 1 → Phase 2 → Phase 2.5 → Phase 3 → Phase 4 → Phase 5
```

7 documents, ~500K text. Full architecture specification complete.

### TRACK B: Skill Factory (7 phases)

| Phase | Scope | Status |
|---|---|---|
| F-0 | Foundation (standard, taxonomy, evaluation, handoff, adaptors) | PENDING |
| F-1 | Analysis (inventory 200 repos) | PENDING |
| F-2 | Context (modules company/product/audience/brand/market) | PENDING |
| F-3 | Factory (meta-skill that generates skills) | PENDING |
| F-4 | Dev Team (auditor, security, debugger, tester) | PENDING |
| F-5 | Domain Skills (batch generation) | PENDING |
| F-6 | Integration (end-to-end testing) | PENDING |

**NOTE**: F-0..F-6 are FACTORY phases, NOT architecture document phases (Phase 0-5).

### TRACK C: Research
- TASK-02B: Non-Claude system prompts (PENDING)
- TASK-07A/B/C: 200 repos analysis (PENDING)
- TASK-01: Anthropic skills deep dive (DONE)

---

## 5. WORKING PRINCIPLES

- Always Ukrainian for communication
- Read skills FULLY (no range limits)
- Concrete deliverables, not abstractions
- Anti-sycophancy: validate for cognitive biases
- Evidence-based: research backing > speculation
- MECE: mutually exclusive, collectively exhaustive
- Iteration > Perfection, but foundation solid
- Engineering principle: evaluation system first → then analysis
- "Fork → Adapt → Own" for external solutions
- Progressive disclosure: SKILL.md < 500 lines, details → references/

---

## 6. EXTENDED CONTEXT

Detailed information in [CONTEXT_EXTENDED.md](./CONTEXT_EXTENDED.md):
- S1 Methodological base (YaKomanda, Org Skills, Anthropic patterns)
- S2 Identified gaps (8 gaps with updated statuses)
- S3 200 repos on disk (paths, strategy)
- S4 Research — status
- S5 Technical parameters Claude API
- S6 Cross-document dependencies
- S7 Reference documents
