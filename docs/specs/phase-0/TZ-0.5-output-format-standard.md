# TZ-0.5: Output Format Standard

> **Phase**: 0 — Foundation Layer
> **Priority**: P1
> **Sessions**: 1-2
> **Dependencies**: TZ-0.1 (Skill Standard — defines task types)
> **Verdict**: ADAPT 50% | BUILD 30% | COPY 20%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.7

---

## 1. Мета

Визначити стандартний формат виходу для кожного з 4 типів задач
(analytical / generative / transformational / orchestration) та правила
адаптації під різні рантайми (Telegram MarkdownV2, Claude Code files,
Claude.ai Artifacts). Включає self-check rubric, який агент виконує
ПЕРЕД видачею результату.

**Без цього ТЗ**: кожен скіл видає результат у довільному форматі →
агрегація неможлива → orchestration pipeline ламається →
Telegram відправляє "сирий" markdown який ламає MarkdownV2.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. 4 Output Templates (per task type)

**1. ANALYTICAL Output** (research, audit, analysis)

```markdown
## Executive Summary
[3-5 sentences, key findings]

## Methodology
- Sources: [list with grades: NOBEL/PR/IV/PP/HEUR/DISC]
- Limitations: [what was NOT covered]
- Assumptions: [explicit list]

## Findings
### Finding 1: [title]
- **Confidence**: 0.85
- **Evidence**: [grade] — [source citation]
- **Detail**: [analysis text]

### Finding 2: ...

## Gaps & Uncertainties
- [gap 1 — what data is missing]
- [gap 2]

## Recommendations
1. [Priority HIGH] — [actionable recommendation]
2. [Priority MEDIUM] — ...

## Sources
| # | Source | Grade | Date | URL |
|---|--------|-------|------|-----|
| 1 | ... | IV | 2026-02 | ... |
```

**Self-check**: No claim without cited source? Confidence explicit?

**2. GENERATIVE Output** (copy, content, email)

```markdown
## Content
[Generated content per brief]

## Variants (if applicable)
### Option A: [style/angle]
[content]
### Option B: [style/angle]
[content]

## Quality Metrics
- Brand voice adherence: [1-10]
- Readability: [Flesch score or equivalent]
- SEO keywords: [if applicable]
- Word count: [number]

## Notes
- [considerations, trade-offs made]
```

**Self-check**: Tone matches brand/voice.md? No plagiarism?

**3. TRANSFORMATIONAL Output** (reformat, adapt, convert)

```markdown
## Input Summary
[What was given: format, size, key content]

## Output
[Transformed result]

## Change Log
- [what was added]
- [what was removed]
- [what was restructured]
- [data integrity check: nothing lost]
```

**Self-check**: No data lost in transform? Format valid?

**4. ORCHESTRATION Output** (delegation, routing, aggregation)

```markdown
## Pipeline Status
| Step | Agent | Status | Duration |
|------|-------|--------|----------|
| 1 | MI Analyst | ✅ Done | 12s |
| 2 | Strategist | ✅ Done | 8s |
| 3 | Copywriter | 🔄 Running | — |

## Aggregated Results
[Combined output from sub-agents]

## Conflicts & Inconsistencies
- [conflict 1 between Agent A and Agent B]

## Next Steps / HITL Required
- [ ] Approve strategy (Step 2 output)
- [ ] Review final copy (after Step 3)
```

**Self-check**: All sub-agents reported? Conflicts flagged?

#### B. Runtime Delivery Adaptor

| Runtime | Format | Constraints |
|---------|--------|-------------|
| **NanoClaw (Telegram)** | MarkdownV2 | Max 4000 chars/message, chunked, `message_thread_id` |
| **NanoClaw (large output)** | sendDocument | .xlsx / .pdf / .csv attachment |
| **Claude Code** | File creation | Markdown or JSON files |
| **Claude.ai** | Artifact | Markdown or React component |
| **Cowork** | File creation | .docx / .pdf |

**Telegram MarkdownV2 rules:**
- Escape: `_`, `*`, `[`, `]`, `(`, `)`, `~`, `` ` ``, `>`, `#`, `+`, `-`, `=`, `|`, `{`, `}`, `.`, `!`
- Bold: `*text*` (escape inner asterisks)
- Italic: `_text_`
- Code: `` `code` `` / ` ```block``` `
- Max message: 4096 chars → chunk at paragraph boundaries
- Tables → convert to formatted text (TG has no native tables)

#### C. Channel Adaptor Hints (in SKILL.md)

Each skill includes delivery hints in OUTPUT section:

```markdown
## Channel Adaptor Hints
- telegram_max_chunk: 3800       # chars per message (with margin)
- telegram_table_mode: text      # text | image | document
- telegram_code_blocks: minimal  # minimal | full
- large_output_threshold: 8000   # chars → switch to sendDocument
- voice_tts_enabled: false       # whether voice output supported
```

#### D. Self-Check Rubric (pre-delivery)

Every output MUST pass self-check before sending:

```markdown
## Self-Check (agent runs before delivery)
□ Format matches task type template?
□ Confidence levels explicit (for analytical)?
□ Brand voice adherence checked (for generative)?
□ No data lost (for transformational)?
□ All sub-agents reported (for orchestration)?
□ Output within channel constraints (length, format)?
□ Thread ID correct (reply to right forum topic)?
□ No hallucinated data (all claims sourced)?
```

### 2.2 Excluded

- MarkdownV2 conversion engine implementation (= TZ-2.2 Channel Adaptor)
- Voice TTS output (= TZ-2.4 Voice Pipeline)
- File generation (.pdf/.xlsx creation) (= TZ-2.2)
- Actual content for any skill output

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] 4 output templates documented (analytical/generative/transformational/orchestration)
- [ ] Each template has: structure, self-check rubric
- [ ] Runtime delivery matrix: 5 runtimes × format + constraints
- [ ] Telegram MarkdownV2 rules documented
- [ ] Channel adaptor hints format defined
- [ ] Self-check rubric: 8 items applicable to all outputs
- [ ] Example output for each task type

### Should Pass (P1)

- [ ] `scripts/format-output.ts` — validates output against template
- [ ] Chunking algorithm documented (for Telegram >4000 chars)
- [ ] Table→text conversion rules for Telegram

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── docs/standards/
│   └── output-format.md            ← Full output format standard
├── templates/
│   └── outputs/
│       ├── analytical.md
│       ├── generative.md
│       ├── transformational.md
│       └── orchestration.md
└── scripts/
    └── format-output.ts            ← Output validation
```

### 4.2 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| Architecture §0.7 | `docs/architecture/phase-0-foundation.md` L650-696 | 4 output templates |
| claudegram | `docs/context_doc/Telegram_all/claudegram/` | MarkdownV2 conversion |
| RichardAtCT | `docs/context_doc/Telegram_all/RichardAtCT/` | Chunking patterns |
| Bot API docs | `docs/context_doc/Telegram_all/` | Message limits |

---

## 5. Testing

```bash
# Validate each output template is complete
for type in analytical generative transformational orchestration; do
  npx ts-node scripts/format-output.ts templates/outputs/$type.md
done

# Test MarkdownV2 escaping rules
npx vitest run tests/output/markdown-v2.test.ts
```

---

## 6. Definition of Done

- [ ] 4 output templates documented
- [ ] Delivery matrix complete
- [ ] Self-check rubric in every template
- [ ] Telegram-specific rules documented
- [ ] SPEC-INDEX.md updated: TZ-0.5 = DONE

---

_Cross-references: TZ-0.1 (task types), TZ-0.4 (handoff carries output), TZ-2.2 (implements channel adaptor)_
