# TZ-0.2: Evaluation System (100-Point Rubric)

> **Phase**: 0 — Foundation Layer
> **Priority**: P0
> **Sessions**: 1-2
> **Dependencies**: TZ-0.1 (Skill Standard — defines WHAT to evaluate)
> **Verdict**: ADAPT 50% | BUILD 40% | COPY 10%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.5

---

## 1. Мета

Створити об'єктивну систему оцінки якості скілів (100 балів),
де 50% критеріїв автоматизовані (file/schema checks),
а 50% — Claude semantic review. Кожен скіл проходить цю оцінку
перед деплоєм у production.

**Без цього ТЗ**: немає якісного фільтра → у системі з'являються
скіли з різною якістю → routing ламається → cascade errors.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. 100-Point Rubric (5 Categories)

**A. STRUCTURAL (формат) — 20 балів**

| # | Criterion | Points | Auto-Check |
|---|-----------|--------|------------|
| A1 | File structure matches standard (TZ-0.1) | 0-4 | YES |
| A2 | SKILL.md < 500 lines | 0-4 | YES |
| A3 | Sandwich structure (critical top 5% + bottom 10%) | 0-4 | PARTIAL |
| A4 | Progressive disclosure (references/ used for details) | 0-4 | YES |
| A5 | Naming conventions followed (folder, registry key, display) | 0-4 | YES |

**B. CONTENT (зміст) — 30 балів**

| # | Criterion | Points | Auto-Check |
|---|-----------|--------|------------|
| B1 | Identity clear and specific ("I am X, I do Y") | 0-5 | PARTIAL |
| B2 | Boundaries defined ("I do NOT do Z") | 0-5 | PARTIAL |
| B3 | Anti-hallucination shields present | 0-5 | PARTIAL |
| B4 | Process steps actionable (numbered, concrete) | 0-5 | NO (Claude) |
| B5 | Quality gates between steps (concrete checks) | 0-5 | NO (Claude) |
| B6 | Error handling + thread rules defined | 0-5 | PARTIAL |

**C. VULNERABILITY (захист) — 20 балів**

| # | Criterion | Points | Auto-Check |
|---|-----------|--------|------------|
| C1 | Anti-sycophancy shields | 0-5 | NO (Claude) |
| C2 | Confidence calibration (explicit uncertainty) | 0-5 | NO (Claude) |
| C3 | Hallucination detection signals | 0-5 | NO (Claude) |
| C4 | Task-appropriate tone (no warmth leak) | 0-5 | NO (Claude) |

**D. INTEGRATION (з'єднання) — 15 балів**

| # | Criterion | Points | Auto-Check |
|---|-----------|--------|------------|
| D1 | Input schema defined (what skill expects) | 0-5 | PARTIAL |
| D2 | Output schema defined (what skill returns) | 0-5 | PARTIAL |
| D3 | Context dependencies + thread scope declared | 0-5 | YES |

**E. RUNTIME (сумісність) — 15 балів**

| # | Criterion | Points | Auto-Check |
|---|-----------|--------|------------|
| E1 | NanoClaw compatible (IPC, container mount) | 0-5 | PARTIAL |
| E2 | Claude Code compatible (.claude/skills/) | 0-5 | YES |
| E3 | Claude.ai convertible (Projects) | 0-5 | PARTIAL |

#### B. Scoring Thresholds

| Score | Status | Action |
|-------|--------|--------|
| 90-100 | ✅ Production Ready | Deploy |
| 70-89 | 🟡 Minor Fixes | Fix and re-evaluate |
| 50-69 | 🟠 Significant Rework | Major rewrite needed |
| <50 | 🔴 Reject | Redesign from scratch |

#### C. Auto-Check Script (`scripts/audit-skill.ts`)

Automated checks (covers ~50% of rubric):

```
A1: File structure matches  → check required files exist
A2: Line count < 500       → wc -l SKILL.md
A4: references/ not empty   → check dir non-empty if refs used
A5: Naming follows convention → regex check on folder/frontmatter
D3: context_deps declared   → YAML frontmatter parse
E2: Claude Code compatible  → check no NanoClaw-only deps in SKILL.md
```

#### D. Claude Semantic Review (covers ~50% of rubric)

Script sends SKILL.md to Claude with structured evaluation prompt:

```
Evaluate this skill against criteria B1-B6, C1-C4.
For each criterion, provide:
- Score (0-5)
- Evidence (quote from SKILL.md that supports score)
- Suggestion (if score < 4)
Return JSON: { criterion: { score, evidence, suggestion } }
```

#### E. Evaluation Report Format

```markdown
# Evaluation Report: [skill-name] v[version]

## Summary
- **Total Score**: 82/100 🟡
- **Status**: Minor Fixes Required
- **Evaluated**: 2026-03-15T14:30:00Z
- **Evaluator**: auto + claude-semantic

## Scores by Category
| Category | Score | Max | % |
|----------|-------|-----|---|
| A. Structural | 18 | 20 | 90% |
| B. Content | 22 | 30 | 73% |
| C. Vulnerability | 15 | 20 | 75% |
| D. Integration | 14 | 15 | 93% |
| E. Runtime | 13 | 15 | 87% |

## Detailed Findings
### B3. Anti-hallucination shields — 3/5
**Evidence**: "Only mentions 'verify sources' once in core logic"
**Suggestion**: Add explicit hallucination markers...

## Fix Requirements (to reach 90+)
1. B3: Add 3 hallucination detection signals
2. C1: Strengthen anti-sycophancy shield in Critical Rules
```

### 2.2 Excluded

- Writing actual skills (= TZ-0.3)
- CI/CD pipeline integration (= TZ-0.7 Quality Gate)
- Historical scoring trends / analytics dashboards
- Peer review process (human-to-human review)

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] 100-point rubric fully documented (5 categories, 17 criteria)
- [ ] Each criterion has: name, max points, auto-check flag
- [ ] Scoring thresholds defined (90+/70-89/50-69/<50)
- [ ] `scripts/audit-skill.ts` runs and produces report for template skill
- [ ] Auto-check covers A1, A2, A4, A5, D3, E2 (6+ criteria)
- [ ] Claude semantic review prompt produces valid JSON scores
- [ ] Evaluation report format documented with example
- [ ] Template skill (from TZ-0.1) scores 90+ as reference

### Should Pass (P1)

- [ ] Batch evaluation: run against multiple skills at once
- [ ] Score history: SQLite table for tracking evaluations over time
- [ ] `--fix` mode: auto-fix A-category issues (structural)

### Nice to Have (P2)

- [ ] Comparison report (before/after improvement)
- [ ] Trend dashboard (skill quality over time)

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── docs/standards/
│   └── evaluation-rubric.md        ← Full rubric document
├── scripts/
│   ├── audit-skill.ts              ← Auto-check + Claude review
│   └── evaluation-prompt.md        ← Claude evaluation prompt template
├── src/store/schema/
│   └── evaluations.sql             ← Score history DDL
└── templates/
    └── evaluation-report.md        ← Report template
```

### 4.2 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| Architecture §0.5 | `docs/architecture/phase-0-foundation.md` L496-554 | Rubric structure, auto-check mapping |
| User's rubric | `docs/context_doc/My_skill_and_insite/` | Existing 100-point evaluation |
| Analysis reports | `Analysis_reports_md/` | Evaluation methodology patterns |
| NanoClaw test suite | `src/` + `vitest.config.ts` | Testing patterns to adapt |

### 4.3 SQLite Schema for Score History

```sql
CREATE TABLE IF NOT EXISTS evaluations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    skill_id TEXT NOT NULL,             -- FK to skills.id
    version TEXT NOT NULL,              -- skill version at time of eval
    total_score INTEGER NOT NULL,       -- 0-100
    category_scores TEXT NOT NULL,      -- JSON: {A: 18, B: 22, ...}
    detailed_scores TEXT NOT NULL,      -- JSON: {A1: 4, A2: 3, ...}
    findings TEXT,                      -- JSON array of issues found
    evaluator TEXT DEFAULT 'auto',      -- auto | claude | manual
    status TEXT NOT NULL,               -- production|minor_fixes|rework|rejected
    evaluated_at TEXT NOT NULL,         -- ISO 8601
    FOREIGN KEY (skill_id) REFERENCES skills(id)
);

CREATE INDEX idx_eval_skill ON evaluations(skill_id);
CREATE INDEX idx_eval_status ON evaluations(status);
```

### 4.4 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Claude scores inconsistently | Unreliable ratings | Use temperature=0, structured JSON output |
| Rubric too strict | All skills fail | Start with 70 as "pass", calibrate on first 5 skills |
| Auto-check false positives | Blocks valid skills | --override flag for manual approval |

---

## 5. Testing

```bash
# Run audit on template skill
npx ts-node scripts/audit-skill.ts templates/skill/

# Verify score >= 90 for reference skill
# Verify report format matches template

# Run on intentionally bad skill → should score < 50
npx ts-node scripts/audit-skill.ts tests/fixtures/bad-skill/
```

---

## 6. Definition of Done

- [ ] Rubric document complete (17 criteria, thresholds)
- [ ] audit-skill.ts works end-to-end
- [ ] Template skill scores 90+
- [ ] Report format verified
- [ ] SPEC-INDEX.md updated: TZ-0.2 = DONE

---

_Cross-references: TZ-0.1 (defines what to evaluate), TZ-0.3 (creates skills to be evaluated), TZ-0.7 (integrates evaluation into CI/CD)_
