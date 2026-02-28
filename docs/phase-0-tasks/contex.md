# NanoClaw OS — Context Handoff
**Date**: 2026-02-28 | **Purpose**: onboard next chat session

---

## 1. ЩО БУДУЄТЬСЯ

**NanoClaw OS** — операційна система для AI-маркетинг-відділу на базі Claude Agent SDK.

**Одне речення**: NanoClaw — обгортка над Claude Agent SDK (Node.js/TypeScript), яка отримує повідомлення з Telegram, спавнить ізольовані контейнери з Claude-агентами, дає їм інструменти (MCP, bash, файли), і повертає результат у чат.

**Бізнес-контекст**: Частина ЯКоманда AI Academy — освітня платформа з AI-курсами для маркетологів ($490-990), цільова аудиторія — фрілансери та підприємці ($500-5000/міс).

---

## 2. АРХІТЕКТУРА (Фази 1-2.5 ГОТОВІ)

### Фаза 1: Генеральна Топологія
- **16 архітектурних принципів** (isolation, ownership, communication, security)
- **4 типи ownership**: GOD (адмін), COMPANY (клієнт-компанія), TEAM (група), PUBLIC (канал)
- **8 потоків даних** (A-H): від вхідного повідомлення до scheduled tasks
- **6×6 матриця**: function types × skill categories
- **Runtime**: Apple Container (macOS) або Docker (Linux), SQLite, polling loops

### Фаза 2: Telegram Platform Layer  
- **4 ролі Telegram**: Bot API (групи/команди), MTProto Userbot (особистий акаунт), Channel Publisher, Webhook Receiver
- **Group Discovery Pipeline**: auto-discovery при додаванні бота в групу
- **MTProto через GramJS**: підключення особистого акаунта для розширеної функціональності

### Фаза 3: Claude Platform Layer — ПОТРІБНО НАПИСАТИ
- Вибір моделей per function type (Opus/Sonnet/Haiku)
- Extended Thinking стратегії
- MCP конектори
- Caching + Batching оптимізація
- Session management
- Cost optimization

### Фази 4-5: Skills Layer + Operational Layer — МАЙБУТНЄ

---

## 3. КЛЮЧОВІ АРТЕФАКТИ (у проекті)

| Файл | Що містить | Роль |
|---|---|---|
| `Marketing_Chain_v3_2026.md` | 14 ланок маркетингового ланцюга, evidence-graded frameworks, PMF competitors, discredited research warnings | Domain knowledge для агентів |
| `MECE-карта екосистеми Claude AI` | 13 UI tools, 20+ API, MCP екосистема, JTBD coverage, конкурентний аналіз, обмеження | Технічна база для архітектурних рішень |
| `NanoClaw: архітектура` | Файлова структура, 3 polling loops, message flow, IPC, groups, scheduled tasks, skills philosophy | Runtime reference |
| `MECE_Marketing_Matrix_v5.xlsx` | Матриця маркетингових позицій | Mapping позицій → skills |

---

## 4. МЕТОДОЛОГІЧНА БАЗА (не в проекті, але існує)

### ЯКОМАНДА Agent Prompt System v1.0
- **51 принцип + 5 кандидатів**, 5 фаз: Identity → Information → Process → Validation → Evolution
- 10 🔴 CRITICAL блоків (must-pass), 27 🟡 REQUIRED, 10 🟢 RECOMMENDED
- Decision Matrix: який набір блоків для якого типу агента
- Persona Guide (§9), Cognitive Bias Catalog (§10, 24 біаси)
- Quick Start шаблон, Anti-Patterns (15), Implementation Roadmap

### skill-architect (org skill)
- Формат skills, sandwich-структура, token economics, cognitive patterns, quality criteria

### prompt-enhancer (org skill)  
- Вразливості LLM, detection patterns, task-type classification (4 типи: analytical/generative/transformational/dialogical)

### skill-creator (Anthropic example skill)
- Методологія: capture intent → write → eval loop → iterate, скрипти для тестів

---

## 5. КРИТИЧНІ РІШЕННЯ ПРИЙНЯТІ В ЦЬОМУ ЧАТІ

### 5.1 Генерувати skills з нуля, НЕ адаптувати чужі
- **Причина**: методологія (52 блоки + evidence grades + handoffs) складніша за будь-який GitHub skill
- **Але**: чужі репо (200 штук на диску) використовувати як task checklists і coverage validation
- **Anthropic skills** (офіційні) — аналізувати обов'язково (формат-патерни від творців платформи)

### 5.2 Архітектура трьох шарів
```
Layer 3: DOMAIN SKILLS (маркетинг, дизайн, dev-ops, data, communication, meta)
Layer 2: CONTEXT MODULES (company DNA, product, audience, brand, market)  
Layer 1: FOUNDATION (standard, factory, evaluation, handoff, extraction, runtime)
```

### 5.3 Skill Taxonomy = MECE матриця (НЕ фіксований список)
- **По домену**: marketing, dev-ops, visual, data, communication, meta
- **По функції**: agents, skills, connectors, commands, modules
- Замість "77 позицій" → динамічна матриця домен × функція

### 5.4 Фабрика → Dev Team → Domain Skills (bootstrap sequence)
- Фабрика валідується вручну на 5 тестових skills
- Dev Team генерується фабрикою і далі валідує ВСЕ автоматично

---

## 6. ВИЯВЛЕНІ ГЕПИ (prompt-enhancer vs ЯКОМАНДА)

| Геп | Пріоритет | Суть |
|---|---|---|
| Каскадна верифікація | 🔴🔴 | Помилка агента №3 руйнує ланцюг №4-7. Потрібен confidence_metadata на handoff |
| Signal-based якість | 🔴 | Замість binary PASS/FAIL — verbosity ratio, sycophancy detection, hallucination flags |
| Context budget management | 🔴 | 5 MCP × 10 tools × 1000 tokens = 50K зайнято ДО задачі |
| Task-type routing (runtime) | 🔴 | Один агент виконує 4 типи задач, кожен потребує різного підходу |
| Model selection per agent | 🟡 | Opus для reasoning, Sonnet для генерації, Haiku для sub-agents |
| Tone isolation на handoffs | 🟡 | Warm brand voice → заражає analytical agent → accuracy -10-30% |
| Cost economics | 🟡 | 77 агентів × $0.05-0.50 × 100+/день = до $10K/день без оптимізації |
| Warmth-Accuracy Tradeoff | 🟡 | Apart Research 2025: warmth training → +10-30% помилок для safety-critical |

---

## 7. ПЛАН ФАБРИКИ (6 ФАЗ)

```
ФАЗА 0: STANDARD — skill standard, taxonomy matrix, evaluation framework, 
         handoff protocol, output templates
ФАЗА 1: ANALYSIS — inventory 200 repos ЧЕРЕЗ стандарт з Фази 0
ФАЗА 2: CONTEXT — модулі company/product/audience/brand/market + extraction process
ФАЗА 3: FACTORY — meta-skill що генерує інші skills
ФАЗА 4: DEV TEAM — auditor, security-reviewer, debugger, integration-tester
ФАЗА 5: DOMAIN SKILLS — batch generation по доменах
ФАЗА 6: INTEGRATION — end-to-end testing
```

---

## 8. 200 РЕПО НА ДИСКУ

**Шлях**: `/Users/God_Yurii/Downloads/AI_PROJECT/nanoclow/marketing_skills_repo`

Покривають: маркетинг, розробку, безпеку, дизайн, MCP, Claude Code, Anthropic cookbook, system prompts, SEO/GEO, відео, соціальні мережі, email, ads.

**Стратегія використання**: 
1. Автоматичний inventory (bash скрипти → JSON)
2. Deep analysis батчами по 5-7 через evaluation framework
3. Synthesis → coverage matrix + task registry + standard updates

---

## 9. ДОСЛІДЖЕННЯ ПРОВЕДЕНІ

| Що | Статус | Де результат |
|---|---|---|
| Anthropic public skills (формат-патерни) | ✅ Переглянуто в чаті | Патерни: concrete code > abstract, critical rules at end, quick reference table |
| System prompts (Claude Code, Claude.ai) | ✅ TASK-02 виконано окремо | Окрема сесія |
| System prompts (Bolt, Cursor, Lovable, Manus, Replit) | ⏳ TASK-02B створено ТЗ | Файл task-02b |
| 200 GitHub repos | ⏳ ТЗ готові (07A/B/C) | Файли task-07a/b/c |
| skill-architect references | ⏳ Не всі прочитані | prompting-methods.md, prompt-anti-patterns.md |

---

## 10. ПОТОЧНА ЗАДАЧА

**Фаза 3 архітектурного плану**: Claude Platform Layer & Runtimes — модельний вибір, Extended Thinking, MCP, caching, batching, session management, cost optimization, container↔SDK інтеграція.

**Відомі факти для Фази 3**:
- Opus 4.6: $5/$25 MTok, 200K (1M beta), 128K output — складні агенти, стратегія
- Sonnet 4.6: $3/$15 MTok, 200K (1M beta), 64K output — щоденна робота
- Haiku 4.5: $1/$5 MTok, 200K, 64K output — real-time, sub-agents
- Extended Thinking: до 128K токенів, adaptive (4.6) або budget_tokens (4.5)
- Prompt Caching: 5-хв (0.1x read) та 1-год (beta)
- Batch API: 50% знижка, 24-год ліміт
- Compaction API: серверна компресія для нескінченних розмов (Beta, Opus 4.6)
- Tool Search: динамічне виявлення інструментів з великих каталогів

---

## 11. ПРИНЦИПИ РОБОТИ З КОРИСТУВАЧЕМ

- Завжди українською
- Skills читати ПОВНІСТЮ (no range limits)
- Конкретні deliverables, не абстракції
- Anti-sycophancy: валідувати свої відповіді на когнітивні помилки
- Evidence-based: research backing > speculation
- MECE: mutually exclusive, collectively exhaustive структурування
- Iteration > Perfection, але фундамент має бути solid