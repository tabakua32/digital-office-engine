# Full Roadmap Design — NanoClaw OS

**Date**: 2026-02-28
**Status**: APPROVED
**Approach**: B — Two Tracks with Merge Points

---

## Overview

Two-track parallel approach to build NanoClaw OS from analysis through production.
- **Track A** (Chat 1): Anthropic intellectual core — analysis → validation → synthesis
- **Track B** (Chat 2): Platform analysis — TS + TG + external ecosystem
- **Merge Point 1**: Standardization + Universal Factory
- **Track C** (Chat 1): Platform tools — TG skills, TS instruments, dev tools
- **Track D** (Chat 2): Domain artifacts — Marketing (~73 files) + Tech dept (~20-30 files)
- **Merge Point 2**: Architecture integration
- **Final**: NanoClaw integration → E2E testing

**Key principle**: Factory produces ALL artifact types — skills, agents, templates, commands, context files with placeholders.

---

## Prerequisites — Data Loading (User action)

Before tracks start, user loads into `context_doc/`:

| Source | Target directory | Purpose |
|--------|-----------------|---------|
| TypeScript handbook + lib types | `context_doc/typescript_docs/` | TS skills, NanoClaw source understanding |
| Claude Agent SDK (npm package + docs) | `context_doc/claude_agent_sdk/` | Container architecture, IPC, tools |
| Claude API docs (Messages, Batch, Caching, Thinking) | `context_doc/claude_api_docs/` | Model matrix, cost optimization, token limits |
| Telegram Bot API 9.3 | `context_doc/telegram_api/` | Messaging, keyboards, forums, payments, streaming |
| Telegram MTProto / GramJS | `context_doc/telegram_mtproto/` | Userbot capabilities (Phase 2.5) |

**Ready criterion**: All 5 directories created with content.

---

## TRACK A — Intellectual Core (Chat 1, sequential)

### A1. Anthropic Platform Documentation Analysis (~1 session)
- **Input**: `context_doc/claude_agent_sdk/`, `context_doc/claude_api_docs/`, Anthropic Cookbook
- **Process**: Extract architectural patterns, constraints, recommended practices, runtime compatibility requirements
- **Output**: `foundation/analysis/anthropic_platform_analysis.md`
- **Why first**: These are the "rules of the game" — everything else must conform

### A2. Claude System Prompt Analysis (~0.5 session)
- **Input**: A1 + `context_doc/claude_skills/` (current system prompt files)
- **Process**: Understand what Claude "knows from birth" vs what needs teaching via skills. Map safety blocks, tool definitions, behavioral defaults
- **Output**: `foundation/analysis/system_prompt_analysis.md`
- **Validation**: Compare with existing `Analysis_reports_md/system_prompts_analysis.md` → produce diff/corrections

### A3. Skills/MCP/Agents Ecosystem Analysis (~1 session)
- **Input**: A1+A2 + `context_doc/claude_skills/` (68 skills, 48 plugins, 14 connectors)
- **Process**: With platform understanding — extract format patterns, orchestration patterns, safety patterns. Also scan programming plugins for potential dev skill opportunities (evaluation rubric input)
- **Output**: `foundation/analysis/skills_ecosystem_analysis.md`
- **Validation**: Compare with existing 3 reports (skills, commands, connectors) → merge/correct
- **Additional**: List of Anthropic programming skills that could be adopted for our dev department

### A4. Competitive Prompts Analysis (~0.5 session)
- **Input**: A1-A3 + leaked prompts (Manus, Cursor, Bolt, Lovable, Replit)
- **Process**: What do competitors do better? Which patterns to adopt?
- **Output**: `foundation/analysis/competitive_analysis.md`
- **Validation**: Compare with existing `agent_prompts_analysis.md`

### A5. Validation + Cross-Synthesis (~1 session)
- **Input**: A1-A4 + all 7 existing reports from `Analysis_reports_md/`
- **Process**: Cross-validate new analyses with existing. What's confirmed? What's refuted? What's new? Produce authoritative synthesis
- **Output**: `foundation/analysis/meta_synthesis_v2.md` (supersedes `meta_engineering_principles.md`)
- **This is the key artifact** — standard quality depends on it

### A6. Business Requirements Synthesis (~0.5 session)
- **Input**: A5 + YAKOMANДА (52 blocks), Marketing Chain v3 (14 links), NanoClaw architecture, PROJECT_MASTER.md
- **Process**: Map theoretical patterns to real needs. YAKOMANДА blocks = building blocks for ALL skills (not just marketing). Evidence Grading = standard for ALL handoffs. Decision Matrix = block selection by task type
- **Output**: `foundation/analysis/business_requirements_synthesis.md`
- **Critical**: This shapes the FACTORY requirements, not just marketing department

**Track A Total**: ~4-5 sessions

---

## TRACK B — Platform Analysis (Chat 2, parallel with A)

### B1. TypeScript Platform Analysis (~1 session)
- **Input**: `context_doc/typescript_docs/` + NanoClaw `src/` (read-only)
- **Process**: Understand NanoClaw codebase architecture, identify extension points, TS constraints for skills, type system patterns
- **Output**: `foundation/analysis/typescript_platform_analysis.md`
- **Additional**: NanoClaw source mapping — hooks, channels, container runner, IPC

### B2. Telegram Platform Analysis (~1 session)
- **Input**: `context_doc/telegram_api/` + `context_doc/telegram_mtproto/`
- **Process**: Full Bot API 9.3 mapping — messaging types, inline keyboards, forums, payments, streaming, Mini Apps, MTProto capabilities
- **Output**: `foundation/analysis/telegram_platform_analysis.md`
- **Additional**: API methods → NanoClaw capabilities → gaps table

### B3. External Ecosystem Analysis (~1 session)
- **Input**: `context_doc/marketing_skills_repo/` + community repos + external MCP servers
- **Process**: Which external skills/MCP can be used as-is? Which need adaptation? Which must be written from scratch?
- **Output**: `foundation/analysis/external_ecosystem_analysis.md`
- **Additional**: Classification table: "use as-is" vs "adapt" vs "write from scratch"

**Track B Total**: ~3 sessions (runs parallel with Track A → 0 additional time)

---

## MERGE POINT 1 — Standardization + Universal Factory

**Prerequisite**: Both tracks A and B completed. All analysis files in `foundation/analysis/`.

### M1. Standardization (~2 sessions)

#### M1.1 Artifact Standard → `foundation/skill_standard.md`
- **Input**: All 9+ analyses + TASK-00A spec
- **Process**: Unified format for ALL artifact types:
  - **Skills**: SKILL.md (<500 lines, sandwich structure, progressive disclosure)
  - **Agents**: AGENT.md (identity blocks, boundaries, handoff contracts)
  - **Commands**: COMMAND.md (routing, input/output schema)
  - **Templates**: TEMPLATE.md (output format, self-check rubric)
  - **Context files**: CONTEXT.md (placeholders, extraction schema)
- Anthropic compatibility matrix (NanoClaw, Claude Code, Claude.ai, Cowork)
- **Quality gate**: Format works across all 4 runtimes

#### M1.2 Taxonomy → `foundation/skill_taxonomy.md`
- **Input**: M1.1 + PROJECT_MASTER (6×6 matrix) + YAKOMANДА (52 blocks → Decision Matrix)
- **Process**: MECE matrix — 6 domains × 6 function types
  - Per cell: name, artifact_type (skill/agent/command/template/context), task_type, chain_link, model_tier, bias_set, YAKOMANДА blocks needed
- **Quality gate**: Matrix is MECE, covers both marketing dept (~73 files) and tech dept (~20-30 files)

#### M1.3 Evaluation + Infrastructure → 4 documents
- `foundation/evaluation_framework.md` — 100-point scoring rubric (applies to ALL artifact types)
  - Also: scan of Anthropic programming plugins → identify dev skills for adoption
- `foundation/handoff_protocol.md` — JSON handoff schema + 5 worked examples
- `foundation/output_templates/` — 4 templates (analytical, generative, transformational, orchestration)
- `foundation/process_templates.md` — 5 core processes (campaign, content, onboarding, intelligence, artifact creation)
- **Quality gate**: Numeric criteria, ≥5 handoff examples, runtime versions per template

### M2. Universal Factory (~2 sessions)

#### M2.1 Synthesis + Design → `foundation/synthesis/` (6 files)
- Consolidated patterns (≥30), gap analysis, handoff contracts, output templates, position mapping (77+ rows), factory architecture
- Corresponds to TASK-04

#### M2.2 Build Factory → `nanoclaw-skill-factory/`
- SKILL.md (<500 lines) — 5-phase workflow: SCOPE → DESIGN → BUILD → VERIFY → PACKAGE
- Works for ALL artifact types (skills, agents, templates, commands, context files)
- `references/` (10+ files): format-standard, patterns, handoff, vulnerability-shields, yakomanda-blocks, cognitive-models, position-mapping, nanoclaw-constraints, output-templates/
- `scripts/`: audit_artifact.py (compliance checker), generate_skeleton.py (position-to-skeleton for any artifact type)
- `assets/`: templates per artifact type (skill-template.md, agent-template.md, command-template.md, context-template.md)
- Corresponds to TASK-05

#### M2.3 Validate Factory → 3-5 test artifacts
- Create 3-5 test artifacts through factory (mix of skill, agent, command)
- Run through audit_artifact.py
- Fix factory based on findings
- **Quality gate**: ≥3 artifacts pass audit at ≥70 points
- Corresponds to TASK-06

**Merge Point 1 Total**: ~4 sessions

---

## TRACK C — Platform Tools (Chat 1, after Merge Point 1)

### C1. Telegram Skills (~2 sessions)
- **Input**: Factory (M2) + `telegram_platform_analysis.md` (B2)
- **Process**: Factory generates TG skills: messaging, keyboards, forums, payments, streaming, Mini Apps, MTProto monitoring
- **Output**: `skills/communication/telegram/` — full TG skill set
- **Quality gate**: Each skill passes audit ≥70, covers real API methods

### C2. TypeScript Instruments (~1 session)
- **Input**: Factory (M2) + `typescript_platform_analysis.md` (B1)
- **Process**: Skills/tools for TS development in NanoClaw context
- **Output**: `skills/dev-ops/typescript/`

### C3. Other Dev Tools (~1 session)
- **Input**: Factory (M2) + external MCP analysis (B3) + programming plugins from M1.3
- **Process**: Integrate external MCP servers, create connectors, adapt community skills, create dev skills identified during evaluation
- **Output**: `skills/dev-ops/tools/`

**Track C Total**: ~4 sessions

---

## TRACK D — Domain Artifacts (Chat 2, parallel with C)

### D1. Marketing Department (~3-4 sessions, largest volume)
- **Input**: Factory (M2) + YAKOMANДА + Chain v3 + position_skill_mapping
- **Process**: Factory generates ~73 artifacts for marketing department:
  - Skills (content creation, SEO, analytics, social media, etc.)
  - Agents (copywriter, designer, analyst, strategist, etc.)
  - Commands (campaign-launch, content-review, competitor-scan, etc.)
  - Templates (brief, report, post, presentation, etc.)
  - Context files with placeholders (company/, product/, audience/, brand/, market/)
- **Output**: `skills/marketing/` + `groups/marketing/` integration
- **Quality gate**: ≥20 artifacts pass audit ≥70, cover all 14 chain links

### D2. Technical Department (~1-2 sessions)
- **Input**: Factory (M2) + NanoClaw architecture + dev skills from M1.3
- **Process**: Factory generates ~20-30 artifacts:
  - Skills (deploy, monitor, test, debug, etc.)
  - Agents (devops-engineer, code-reviewer, etc.)
  - Commands (deploy-prod, run-tests, health-check, etc.)
  - Context files (infra/, services/, environments/)
- **Output**: `skills/dev-ops/` + deployment integration

### D3. Meta/Communication Skills (~1 session)
- **Input**: Factory + cross-department needs
- **Output**: `skills/meta/` + `skills/communication/`
- Includes: orchestration, handoff management, cost tracking, HITL

**Track D Total**: ~5-7 sessions (runs parallel with Track C → 0 additional time)

---

## MERGE POINT 2 + Final Integration

### F1. Architecture Mapping + NanoClaw Integration (~2-3 sessions)
- **Input**: All artifacts from C+D + NanoClaw source (read-only) + architecture docs (Phases 1-5)
- **Process**:
  - Map data flows across all artifacts
  - Integrate into `groups/` structure (main, marketing, global)
  - Configure container mounts, IPC paths
  - Set up channel adaptors (TG → skill → output → TG)
- **Output**: Working NanoClaw with connected artifacts
- **Quality gate**: `npm test` pass, `npm run typecheck` clean, manual TG test

### F2. Testing + Bug Fixing (~2 sessions)
- **Input**: Integrated system
- **Process**: E2E tests via Telegram, bug fixing, performance tuning
- **Output**: Production-ready system
- **Quality gate**: 5 E2E scenarios pass, cost tracking works, HITL works, all departments functional

**Final Total**: ~4-5 sessions

---

## Session Estimates Summary

| Phase | Steps | Sequential | With parallelism |
|-------|-------|-----------|-----------------|
| **Prerequisites** | Data loading | 0 (user) | 0 |
| **Track A** | A1-A6 | 4-5 | 4-5 |
| **Track B** | B1-B3 | 3 | **0** (parallel with A) |
| **Merge Point 1** | M1-M2 | 4 | 4 |
| **Track C** | C1-C3 | 4 | 4 |
| **Track D** | D1-D3 | 5-7 | **0** (parallel with C) |
| **Final** | F1-F2 | 4-5 | 4-5 |
| **TOTAL** | | 24-29 | **~13-18 sessions** |

Parallelism saves ~40%. Each session = ~1-2 hours of real work.

---

## Artifact Counts by Department

| Department | Skills | Agents | Commands | Templates | Context | Total |
|-----------|--------|--------|----------|-----------|---------|-------|
| Marketing | ~30 | ~15 | ~10 | ~10 | ~8 | **~73** |
| Technical | ~10 | ~5 | ~8 | ~4 | ~3 | **~30** |
| Meta/Comm | ~5 | ~3 | ~3 | ~2 | ~2 | **~15** |
| Platform (TG/TS) | ~10 | ~2 | ~5 | ~3 | ~0 | **~20** |
| **TOTAL** | **~55** | **~25** | **~26** | **~19** | **~13** | **~138** |

---

## Quality Gates (per merge point)

### Merge Point 1 Gates
- [ ] All 9+ analysis files complete and cross-validated
- [ ] meta_synthesis_v2.md supersedes previous reports
- [ ] skill_standard.md covers all 5 artifact types
- [ ] taxonomy MECE (0 overlaps, 0 gaps)
- [ ] evaluation rubric has numeric criteria (100-point scale)
- [ ] factory SKILL.md <500 lines
- [ ] audit_artifact.py works
- [ ] ≥3 test artifacts pass audit ≥70

### Merge Point 2 Gates
- [ ] ≥20 marketing artifacts pass audit ≥70
- [ ] ≥10 tech artifacts pass audit ≥70
- [ ] TG skills cover main API methods
- [ ] All artifacts have handoff contracts
- [ ] Dev skills identified from Anthropic plugins created

### Final Gates
- [ ] `npm test` pass
- [ ] `npm run typecheck` clean
- [ ] 5 E2E scenarios via Telegram pass
- [ ] Cost tracking functional
- [ ] HITL protocol functional
- [ ] All departments have working skills

---

## Key Decisions

1. **Universal factory** — produces skills, agents, templates, commands, context files (not just skills)
2. **YAKOMANДА blocks** are building blocks for ALL artifacts (not just marketing)
3. **Evidence Grading** (Chain v3) is standard for ALL handoffs
4. **Two departments** as primary output: Marketing (~73) + Technical (~30)
5. **Evaluation rubric** also identifies dev skill opportunities from Anthropic plugins
6. **Approach B** — two parallel tracks with merge points (~40% time savings)
7. **1 chat + subagents** for each track (safer than 2 chats in same repo)
8. **Existing reports** (A- quality) → validation pass, not full redo
