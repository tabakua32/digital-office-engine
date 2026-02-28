# NanoClaw OS — Extended Context Reference
**Date**: 2026-02-28 | **Source**: Перенесено з CLAUDE.md v3 при стисненні до v4

---

## 1. МЕТОДОЛОГІЧНА БАЗА

### ЯКОМАНДА Agent Prompt System v1.0
- **51 принцип + 5 кандидатів**, 5 фаз: Identity → Information → Process → Validation → Evolution
- 10 CRITICAL, 27 REQUIRED, 10 RECOMMENDED
- Decision Matrix, Persona Guide (§9), Cognitive Bias Catalog (§10, 24 біаси)

### Org Skills у проєкті
- **skill-architect**: формат skills, sandwich-структура, token economics
- **prompt-enhancer**: вразливості LLM, detection patterns, 4 task-types

### Anthropic format patterns (з аналізу офіційних skills)
- Concrete Code > Abstract Instruction
- Critical Rules as list at end (sandwich implementation)
- Quick Reference Table на початку

---

## 2. ВИЯВЛЕНІ ГЕПИ

| Геп | Пріоритет | Суть | Де вирішувати | Статус |
|---|---|---|---|---|
| Каскадна верифікація | CRITICAL | Помилка агента №3 руйнує ланцюг №4-7 | Foundation: handoff_protocol | Адресовано в Фаза 0 §0.6 |
| Signal-based якість | CRITICAL | Замість PASS/FAIL — verbosity ratio, sycophancy detection | Foundation: evaluation_framework | Адресовано в Фаза 0 §0.5 |
| Context budget management | CRITICAL | 5 MCP x 10 tools x 1000 tokens = 50K ДО задачі | Phase 3 + Foundation | Адресовано в Фаза 3 §3.5 |
| Task-type routing | CRITICAL | Один агент — 4 типи задач | Foundation: skill_standard | Адресовано в Фаза 0 §0.2 |
| Model selection per agent | REQUIRED | Scale Paradox: більші моделі галюцинують більше | Phase 3 | Адресовано в Фаза 3 §3.3 |
| Tone isolation на handoffs | REQUIRED | Warmth → accuracy -10-30% (Apart Research 2025) | Foundation: handoff_protocol | Адресовано в Фаза 0 §0.6 |
| Cost economics | REQUIRED | До $10K/день без оптимізації | Phase 3 | Адресовано в Фаза 3 §3.9 |
| Automated monitoring | REQUIRED | 77 агентів 24/7 — alerting, drift detection | Phase 5 | Адресовано в Фаза 5 §5.4 |

---

## 3. 200 РЕПО НА ДИСКУ

**Шлях**: `/Users/God_Yurii/Downloads/AI_PROJECT/nanoclow/marketing_skills_repo`

Покривають: маркетинг, розробку, безпеку, дизайн, MCP, Claude Code, Anthropic cookbook, system prompts, SEO/GEO, відео, соціальні мережі, email, ads.

**Стратегія**: inventory (bash→JSON) → deep analysis (батчі по 5-7) → synthesis → coverage matrix.

**Ключові**: agentkits-marketing, ai-marketing-claude-code-skills, claude-code-skills, claude-cookbooks, awesome-mcp-servers, marketing-skills, social-agents.

---

## 4. ДОСЛІДЖЕННЯ — СТАТУС

| Що | Статус | Результат |
|---|---|---|
| Anthropic public skills | DONE | Concrete Code > Abstract; Critical Rules at end; Quick Reference Table |
| System prompts (Claude Code, Claude.ai) | DONE TASK-02 | Окрема сесія |
| System prompts (Bolt, Cursor, Lovable, Manus, Replit) | PENDING TASK-02B | ТЗ готове |
| 200 GitHub repos | PENDING TASK-07A/B/C | ТЗ готові |
| skill-architect references | PENDING | prompting-methods.md, prompt-anti-patterns.md |

---

## 5. ТЕХНІЧНІ ПАРАМЕТРИ CLAUDE API

- **Opus 4.6**: $5/$25 MTok, 200K (1M beta), 128K output — складні агенти, стратегія
- **Sonnet 4.6**: $3/$15 MTok, 200K (1M beta), 64K output — щоденна робота
- **Haiku 4.5**: $1/$5 MTok, 200K, 64K output — real-time, sub-agents
- **Extended Thinking**: до 128K токенів, effort: low/medium/high/max (4.6), budget_tokens (4.5 only)
- **Prompt Caching**: 5-хв (0.1x read) та 1-год (beta)
- **Batch API**: 50% знижка, 24-год ліміт
- **Compaction API**: серверна компресія для нескінченних розмов (Beta, Opus 4.6)
- **Tool Search**: динамічне виявлення інструментів з великих каталогів (deferred: true)
- **Structured Outputs**: гарантована відповідність JSON-схемі
- **Code Execution**: sandbox, безкоштовно з web search/fetch
- **Scale Paradox**: більші моделі галюцинують більше (Opus ~10% vs Sonnet <5%)
- **Warmth-Accuracy Tradeoff**: Apart Research 2025 — warmth training → +10-30% помилок

---

## 6. CROSS-DOCUMENT DEPENDENCIES

```
Фаза 0 ───foundation───→ ALL Phases (skill standard, evaluation, handoff)
Фаза 1 ←──references──── Фаза 4 (§4.14: deltas to Phase 1)
Фаза 2 ←──references──── Фаза 4 (§4.14: deltas to Phase 2)
Фаза 2 ←──extends─────── Фаза 2.5 (MTProto додає 61 можливість)
Фаза 2 ←──detail──────── GDP (Group Discovery деталізує Flow G з Фази 4)
Фаза 3 ←──references──── Фаза 4 (§4.14: deltas to Phase 3; Flows I,J reference Phase 3)
Фаза 4 ───contains─────→ Channel Adaptors (§4.12, Foundation-level spec)
Фаза 4 ───contains─────→ Memory Architecture (§4.8, 3 рівні)
Фаза 4 ───contains─────→ HITL Convention (§4.6, 5 типів)
```

---

## 7. REFERENCE DOCUMENTS (не архітектура NanoClaw)

| Файл | Роль | Розташування |
|---|---|---|
| `Marketing_Chain_v3_2026.md` | 14 ланок маркетингового ланцюга | context_doc/ або зовнішній |
| `Повна MECE-карта екосистеми Claude AI` | 13 UI tools, 20+ API, MCP, JTBD | context_doc/ або зовнішній |
| `NanoClaw: архітектура як задумав розробник` | Оригінальний код: 3 loops, message flow, IPC | context_doc/ або зовнішній |
| `MECE_Marketing_Matrix_v5.xlsx` | Матриця маркетингових позицій → skills mapping | context_doc/ або зовнішній |
| `group_discovery_pipeline.md` | Auto-discovery pipeline | TASK/task_old/ |
