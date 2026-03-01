# TZ-0.7: Quality Gate + Integration Tests

> **Phase**: 0 — Foundation Layer
> **Priority**: P2
> **Sessions**: 1-2
> **Dependencies**: TZ-0.2 (Evaluation rubric), TZ-0.3 (Template Factory)
> **Verdict**: ADAPT 40% | BUILD 40% | COPY 20%
> **Architecture ref**: `docs/architecture/phase-0-foundation.md` §0.5 (auto-check), §0.9 (principles)

---

## 1. Мета

Створити автоматизований Quality Gate — pipeline перевірок, який кожен
скіл повинен пройти перед потраплянням у production. Інтегрує evaluation
rubric (TZ-0.2), структурну валідацію, та integration tests (skill працює
в реальному pipeline: channel → routing → skill → output).

**Без цього ТЗ**: скіли потрапляють у production без перевірки →
рантайм-помилки → cascade failures → деградація якості.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Quality Gate Pipeline (4 stages)

```
Stage 1: STRUCTURE CHECK (auto, 5 sec)
├── Files exist (SKILL.md, required dirs)
├── YAML frontmatter valid
├── Line count < 500
├── Naming conventions match
└── PASS/FAIL → blocks if FAIL

Stage 2: EVALUATION RUBRIC (auto + Claude, 30 sec)
├── Run audit-skill.ts (TZ-0.2)
├── Score >= 70 required
├── Score >= 90 for "production ready"
└── PASS/WARN/FAIL → blocks if FAIL

Stage 3: TYPE CHECK (auto, 10 sec)
├── TypeScript types validate (if applicable)
├── Handoff schema valid (TZ-0.4)
├── Output format matches task type (TZ-0.5)
└── PASS/FAIL → blocks if FAIL

Stage 4: INTEGRATION TEST (auto, 60 sec)
├── Skill loads in mock NanoClaw container
├── Receives sample input → produces output
├── Output matches expected format
├── Thread routing works (if thread_scope != any)
└── PASS/FAIL → blocks if FAIL
```

#### B. Gate Command

```bash
# Run full quality gate on a skill
npx ts-node scripts/quality-gate.ts skills/marketing-content-copywriter/

# Output:
# Stage 1: STRUCTURE ✅ PASS (0.5s)
# Stage 2: EVALUATION 🟡 WARN - Score: 82/100 (15s)
# Stage 3: TYPE CHECK ✅ PASS (2s)
# Stage 4: INTEGRATION ✅ PASS (45s)
#
# RESULT: APPROVED (with warnings)
# - B3: Anti-hallucination shields could be stronger (3/5)
# - Action: Fix for score 90+ before next review cycle
```

#### C. Integration Test Framework

Tests run in isolated environment using vitest:

```typescript
// tests/skills/[skill-name].test.ts
import { describe, it, expect } from 'vitest';
import { loadSkill, mockContainer, mockInput } from '../helpers';

describe('marketing-content-copywriter', () => {
  it('loads SKILL.md without errors', async () => {
    const skill = await loadSkill('marketing-content-copywriter');
    expect(skill.frontmatter.type).toBe('skill');
    expect(skill.frontmatter.domain).toBe('marketing/content');
  });

  it('produces generative output format', async () => {
    const output = await mockContainer.execute(skill, {
      input: 'Write article about AI marketing',
      context: { brand_voice: 'professional' }
    });
    expect(output).toContain('## Content');
    expect(output).toContain('## Quality Metrics');
  });

  it('respects thread scope', async () => {
    const result = await mockContainer.route({
      skill,
      thread_id: 43,
      thread_domain: 'marketing/content'
    });
    expect(result.activated).toBe(true);
  });

  it('rejects off-domain requests', async () => {
    const result = await mockContainer.route({
      skill,
      thread_id: 46,
      thread_domain: 'dev-ops'
    });
    expect(result.activated).toBe(false);
  });
});
```

#### D. CI Integration

Quality gate runs automatically:
1. **On skill creation** — after `create-skill.ts` generates files
2. **On skill edit** — pre-commit hook (if skill files changed)
3. **On batch review** — `quality-gate.ts --all` reviews all skills

#### E. Gate Results Storage

```sql
CREATE TABLE IF NOT EXISTS gate_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    skill_id TEXT NOT NULL,
    stage TEXT NOT NULL,         -- structure|evaluation|typecheck|integration
    status TEXT NOT NULL,        -- pass|warn|fail
    score INTEGER,               -- evaluation score (stage 2 only)
    details TEXT,                -- JSON: findings, errors
    duration_ms INTEGER,
    run_at TEXT NOT NULL,        -- ISO 8601
    FOREIGN KEY (skill_id) REFERENCES skills(id)
);

CREATE INDEX idx_gate_skill ON gate_results(skill_id);
CREATE INDEX idx_gate_status ON gate_results(status);
```

### 2.2 Excluded

- Production deployment pipeline (= Phase 5 Docker)
- Human peer review process
- Performance benchmarking (response time, token usage)
- A/B testing framework for skills

---

## 3. Acceptance Criteria

### Must Pass (P0)

- [ ] 4-stage pipeline defined and documented
- [ ] `quality-gate.ts` script runs all 4 stages
- [ ] Template skill (from TZ-0.3) passes all stages
- [ ] Integration test framework with mock container
- [ ] Gate results stored in SQLite
- [ ] PASS/WARN/FAIL statuses with clear thresholds

### Should Pass (P1)

- [ ] `--all` mode: batch evaluation of all skills
- [ ] Pre-commit hook integration
- [ ] Gate history: trend of quality over time

---

## 4. Implementation Notes

### 4.1 Output Files

```
digital-office-engine/
├── scripts/
│   └── quality-gate.ts             ← Main gate runner
├── tests/
│   ├── helpers/
│   │   ├── load-skill.ts           ← Skill loader for tests
│   │   ├── mock-container.ts       ← Mock NanoClaw environment
│   │   └── mock-input.ts           ← Sample inputs per task type
│   └── skills/
│       └── [skill-name].test.ts    ← Per-skill integration tests
├── src/store/schema/
│   └── gate-results.sql            ← Results DDL
└── docs/standards/
    └── quality-gate.md             ← Gate documentation
```

### 4.2 Key References

| Source | Path | What to Extract |
|--------|------|-----------------|
| NanoClaw tests | `vitest.config.ts` + `tests/` | Existing test patterns (436 tests) |
| TZ-0.2 output | `scripts/audit-skill.ts` | Evaluation integration |
| Anthropic testing | `docs/context_doc/antropic_docs/claude-code/` | Testing best practices |

### 4.3 Risks

| Risk | Mitigation |
|------|------------|
| Integration tests too slow | Mock Claude API responses, skip real API calls |
| False failures | `--override` flag + manual approval path |
| Gate blocks development | Stage 1-3 = hard block, Stage 4 = soft warn initially |

---

## 5. Testing

```bash
# Run quality gate on template skill (should pass all)
npx ts-node scripts/quality-gate.ts templates/skill/

# Run on intentionally bad skill (should fail stages 1-2)
npx ts-node scripts/quality-gate.ts tests/fixtures/bad-skill/

# Run full test suite
npx vitest run tests/skills/
```

---

## 6. Definition of Done

- [ ] quality-gate.ts runs 4 stages end-to-end
- [ ] Template skill passes all stages
- [ ] Integration tests created for 3 reference skills
- [ ] Gate results stored in SQLite
- [ ] SPEC-INDEX.md updated: TZ-0.7 = DONE

---

_Cross-references: TZ-0.2 (evaluation rubric = stage 2), TZ-0.3 (template = what we test), TZ-0.1 (standard = what we validate against)_
