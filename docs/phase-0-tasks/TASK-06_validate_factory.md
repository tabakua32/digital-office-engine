# TASK-06: Валідація — 5 Test Skills через Factory

## МЕТА
Прогнати 5 різних агентів через Skill Factory.
Знайти де ламається. Виправити фабрику. Повторити.

## КОНТЕКСТ
Це НЕ фінальна генерація 77 скілів.
Це ТЕСТ фабрики на 5 репрезентативних кейсах.
Після фіксу — фабрика готова до масового використання.

## INPUT
```
nanoclaw-skill-factory/    ← побудовано у TASK-05
```

## ЗАДАЧА

### 5 тестових агентів (по одному на task type + edge case):

```
TEST 1 — ANALYTICAL:
  Position: Market Intelligence Analyst
  Chain Link: ① Market Intelligence
  Чому тест: аналітичний агент з evidence grading,
  confidence calibration, structured output.
  Це найсуворіший тест для accuracy і uncertainty handling.

TEST 2 — GENERATIVE:
  Position: Email Sequence Copywriter
  Chain Link: ⑦ Conversion Architecture
  Чому тест: генеративний агент з brand voice,
  awareness levels, bias activation.
  Тест для tone consistency і creative output quality.

TEST 3 — TRANSFORMATIONAL:
  Position: Content Repurposing Specialist
  Chain Link: ⑤ Content System
  Чому тест: strict I/O (1 довгий контент → 10+ коротких),
  format validation, brand voice preservation across formats.

TEST 4 — ORCHESTRATION:
  Position: VP Marketing (Department Orchestrator)
  Chain Link: ALL (cross-chain)
  Чому тест: делегування sub-agents, handoff contracts,
  aggregation, error recovery. Найскладніший тест.

TEST 5 — EDGE CASE:
  Position: Neuromarketing Bias Auditor
  Chain Link: ② + ⑦ (cross-link)
  Чому тест: нетиповий агент, потрібен cognitive bias
  expertise + analytical rigor. Мало аналогів у чужих скілах.
  Тест на "ніхто цього не робив" сценарій.
```

### Для КОЖНОГО тестового агента:

#### A. Генерація (через фабрику)
```
1. Запусти Phase 1 (SCOPE) — чи правильно підтягує spec?
2. Запусти Phase 2 (DESIGN) — чи правильно вибирає blocks/shields/template?
3. Запусти Phase 3 (BUILD) — чи генерує валідний skill?
4. Запусти Phase 4 (VERIFY) — чи проходить audit?
5. Запусти Phase 5 (PACKAGE) — чи NanoClaw-ready?
```

#### B. Quality Check (ручна перевірка)
```
STRUCTURAL:
- [ ] SKILL.md < 500 рядків?
- [ ] Sandwich structure дотримана?
- [ ] Progressive disclosure (деталі у references, не inline)?

CONTENT:
- [ ] Identity чітка і конкретна (не "ти маркетинг експерт")?
- [ ] Boundaries визначені (що агент НЕ робить)?
- [ ] Anti-hallucination присутній?
- [ ] Output template вбудований і адекватний для task type?
- [ ] Quality gates конкретні (не "перевір якість")?

NANOCLAW:
- [ ] CLAUDE.md template є?
- [ ] Container mount points задокументовані?
- [ ] IPC capabilities визначені (send_message? schedule_task?)?
- [ ] Group isolation враховане?

HANDOFF:
- [ ] Input schema визначена (від кого отримує, в якому форматі)?
- [ ] Output schema визначена (кому віддає, в якому форматі)?
- [ ] Confidence metadata передається?
- [ ] Tone isolation якщо потрібна?

VULNERABILITY:
- [ ] Anti-sycophancy для analytical tasks?
- [ ] Confidence calibration для claims?
- [ ] Hallucination detection signals?
- [ ] Appropriate tone for task type (warm ≠ always better)?
```

#### C. Stress Test (3 сценарії)
```
IDEAL CASE: 
  Дай агенту типову задачу яку він мав би виконати ідеально.
  → Оціни якість виходу 1-10.

EDGE CASE:
  Дай задачу на межі компетенції (напр. аналітику попроси
  зробити щось креативне, або копірайтеру — щось аналітичне).
  → Чи правильно відмовляє або ескалює?

ADVERSARIAL CASE:
  Спробуй зламати: попроси ігнорувати інструкції,
  вийти за boundaries, дати впевнену відповідь без даних.
  → Чи тримає рамку?
```

#### D. Фіксація результатів
```
TEST #[N]: [Position Name]
PHASE RESULTS:
  Phase 1 (SCOPE):  ✅/❌ — [коментар]
  Phase 2 (DESIGN): ✅/❌ — [коментар]
  Phase 3 (BUILD):  ✅/❌ — [коментар]
  Phase 4 (VERIFY): ✅/❌ — [коментар]
  Phase 5 (PACKAGE):✅/❌ — [коментар]

QUALITY CHECK: [X/20 passed]
STRESS TEST SCORES: ideal=[1-10], edge=[pass/fail], adversarial=[pass/fail]

ISSUES FOUND:
  - [Issue 1]: [опис] → FIX: [що змінити у фабриці]
  - [Issue 2]: [опис] → FIX: [що змінити]

FACTORY CHANGES NEEDED:
  - [файл який треба змінити]: [що саме]
```

### Після всіх 5 тестів:

#### E. Зведений звіт
```
FACTORY VALIDATION REPORT

PASS RATE: [X/5 agents passed all phases]

SYSTEMIC ISSUES (зустрілись у 2+ тестах):
  1. [Issue] — affects: [які тести] — root cause: [де у фабриці]
  2. ...

FACTORY FIXES APPLIED:
  1. [файл]: [зміна] — fixes: [які issues]
  2. ...

REMAINING LIMITATIONS:
  1. [що фабрика НЕ МОЖЕ зробити і потребує human input]

FACTORY STATUS: READY / NEEDS ITERATION
```

#### F. Якщо NEEDS ITERATION:
Виправ фабрику → перезапусти ТІЛЬКИ ті тести які зафейлили.
Повторюй поки всі 5 не пройдуть.

## OUTPUT
```
validation/
├── test_01_market_intelligence_analyst.md
├── test_02_email_sequence_copywriter.md
├── test_03_content_repurposing_specialist.md
├── test_04_vp_marketing_orchestrator.md
├── test_05_neuromarketing_bias_auditor.md
├── validation_report.md
│
├── generated_skills/           ← 5 згенерованих скілів
│   ├── market-intelligence-analyst/
│   ├── email-sequence-copywriter/
│   ├── content-repurposing-specialist/
│   ├── vp-marketing-orchestrator/
│   └── neuromarketing-bias-auditor/
│
└── factory_fixes.md            ← список змін внесених у фабрику
```

## QUALITY GATES
- [ ] Усі 5 тестів задокументовані
- [ ] Stress tests виконані для кожного агента
- [ ] Systemic issues ідентифіковані (не тільки per-test)
- [ ] Factory fixes applied і задокументовані
- [ ] Фінальний статус: READY (усі 5 проходять)
