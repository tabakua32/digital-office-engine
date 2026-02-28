# NanoClaw Operating System — Master Architecture Document

**Version**: 2.0
**Date**: 2026-02-27
**Status**: Design Phase

---

## 1. ЩО МИ БУДУЄМО

NanoClaw OS — операційна система для AI marketing department.
Не набір скілів. Не колекція промптів. **Повна операційна система** з трьома шарами.

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 3: DOMAIN SKILLS                                         │
│  Маркетинг │ Розробка │ Дизайн │ Дані │ Комунікація │ Мета     │
│  Динамічна матриця: домен × функція (НЕ фіксований список)     │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: CONTEXT MODULES                                       │
│  Company DNA │ Product │ Audience │ Brand │ Market │ Operations │
│  Заповнюються при onboarding. Живлять КОЖНОГО агента.           │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: FOUNDATION                                            │
│  Skill Standard │ Taxonomy │ Evaluation │ Handoff Protocol      │
│  Output Templates │ Process Templates │ Skill Factory           │
│  Context Extraction │ NanoClaw Runtime                          │
│  Будується ОДИН РАЗ. Все інше стоїть на цьому.                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. КРИТИЧНИЙ CONSTRAINT: ANTHROPIC COMPATIBILITY

Все що ми будуємо МУСИТЬ працювати через:

```
RUNTIME              │ ЯК ВИКОРИСТОВУЄТЬСЯ            │ ЩО ЦЕ ОЗНАЧАЄ ДЛЯ СТАНДАРТУ
─────────────────────┼────────────────────────────────┼──────────────────────────────
NanoClaw             │ Container + CLAUDE.md + IPC     │ File-based skills, markdown,
(Claude Agent SDK)   │ Agent swarms, scheduled tasks   │ container isolation, IPC tools
─────────────────────┼────────────────────────────────┼──────────────────────────────
Claude Code CLI      │ /slash commands + Skills/       │ SKILL.md у .claude/skills/,
                     │ Sub-agents, MCP                 │ references/, scripts/
─────────────────────┼────────────────────────────────┼──────────────────────────────
Claude.ai (browser)  │ Projects + Knowledge Base       │ Custom Instructions format,
                     │ Artifacts, Memory               │ file uploads, artifact output
─────────────────────┼────────────────────────────────┼──────────────────────────────
Cowork (desktop)     │ GUI agent, web research         │ Simplified interface,
                     │ → ready files                   │ file-centric output
```

**НАСЛІДОК**: кожен skill має бути ОДНОЧАСНО:
- SKILL.md для Claude Code / NanoClaw
- Конвертований у Project Custom Instructions для Claude.ai
- Використовувати Anthropic-native output форми (Artifacts, File Creation)
- Сумісний з Claude Agent SDK API patterns

**ДЖЕРЕЛА СТАНДАРТІВ** (вже є у repos):
- Anthropic Cookbook — офіційні рецепти і патерни
- Claude Agent SDK documentation — API контракти
- Claude Code architecture — skill format, sub-agents, MCP
- Кастомні skill architects — існуючі підходи до створення

---

## 3. TAXONOMY: МАТРИЦЯ ДОМЕН × ФУНКЦІЯ

Замість фіксованого списку "77 позицій" — динамічна MECE матриця.
Кількість агентів визначається матрицею, а не навпаки.

### ДОМЕНИ (MECE по предметній області):

```
DOMAIN            │ SCOPE                                    │ CHAIN LINKS
──────────────────┼──────────────────────────────────────────┼────────────
marketing/        │ Весь Marketing Chain v3                  │ ①-⑫
dev-ops/          │ Debug, test, security, deploy, monitor   │ cross-cutting
visual/           │ Design, image, video, infographic        │ ④.5, ⑤, ⑥
data/             │ Analytics, reporting, ETL, dashboards    │ ⑩, ⑫
communication/    │ Email, social, messenger, voice, PR      │ ⑥, ⑦, ⑧
meta/             │ Factory, auditor, orchestrator, router   │ cross-cutting
```

### ФУНКЦІЇ (MECE по типу дії):

```
FUNCTION     │ ЩО РОБИТЬ                            │ АВТОНОМНІСТЬ
─────────────┼──────────────────────────────────────┼─────────────
agent        │ Автономно приймає рішення і діє       │ HIGH
skill        │ Виконує задачу за конкретним запитом  │ MEDIUM
connector    │ MCP інтеграція із зовнішньою системою │ LOW (bridge)
command      │ Slash-команда, швидка дія             │ LOW (atomic)
module       │ Контекстний блок, не виконує — живить │ NONE (data)
process      │ Типовий workflow з кількох кроків     │ ORCHESTRATED
```

### МАТРИЦЯ (приклад заповнення):

```
              │ agent      │ skill        │ connector  │ command    │ module   │ process
──────────────┼────────────┼──────────────┼────────────┼────────────┼──────────┼──────────
marketing/    │ Strategist │ SEO Auditor  │ Google Ads │ /brief     │ ICP      │ Campaign
              │ VP Mktg    │ Copywriter   │ Semrush    │ /compete   │ VoC DB   │ Launch
              │ ...        │ ...          │ ...        │ ...        │ ...      │ ...
──────────────┼────────────┼──────────────┼────────────┼────────────┼──────────┼──────────
dev-ops/      │ Debugger   │ Skill Audit  │ GitHub     │ /test      │ —        │ CI/CD
              │ Security   │ Code Review  │ Sentry     │ /audit     │ —        │ Deploy
──────────────┼────────────┼──────────────┼────────────┼────────────┼──────────┼──────────
visual/       │ Art Dir.   │ Banner Gen   │ Canva      │ /design    │ Brand    │ Rebrand
              │ ...        │ Infographic  │ Figma      │ /mockup    │ Visual   │ ...
──────────────┼────────────┼──────────────┼────────────┼────────────┼──────────┼──────────
...           │ ...        │ ...          │ ...        │ ...        │ ...      │ ...
```

---

## 4. CONTEXT MODULES (Layer 2)

Дані які живлять КОЖНОГО агента. MECE по об'єкту:

```
context_modules/
│
├── company/                    ← ХТО ми
│   ├── identity.md             місія, цінності, origin story, архетип
│   ├── team.md                 хто є, ролі, decision makers
│   └── operations.md           бюджет, інструменти, процеси, KPIs
│
├── product/                    ← ЩО продаємо
│   ├── spec.md                 опис, фічі, value proposition
│   ├── pricing.md              ціна, value ladder, моделі
│   └── positioning.md          Dunford, POP/POD, категорія
│
├── audience/                   ← КОМУ продаємо
│   ├── icp.md                  ICP canvas, сегменти
│   ├── jtbd.md                 jobs, forces, switch timeline
│   ├── voc.md                  voice of customer, цитати, мова
│   └── awareness.md            Schwartz levels, buyer journey
│
├── brand/                      ← ЯК виглядаємо і звучимо
│   ├── voice.md                тон, стиль, vocabulary, do/don't
│   ├── visual.md               кольори, шрифти, imagery
│   └── guidelines.md           brand police, consistency rules
│
├── market/                     ← ДЕ ми знаходимось
│   ├── intelligence.md         TAM/SAM/SOM, trends, PESTEL
│   ├── competitors.md          PMF-confirmed players, SWOT
│   ├── channels.md             де аудиторія, benchmarks
│   └── geo_aeo.md              AI visibility, citations
│
└── META:
    ├── extraction_process.md   ЯК збирати (onboarding flow)
    ├── update_cadence.md       ЯК ЧАСТО оновлювати
    ├── dependencies.md         хто від кого залежить
    └── minimum_viable.md       мінімум для старту vs повний
```

---

## 5. PROCESSES І TEMPLATES

### Типові процеси (process type у матриці):

```
PROCESS              │ КРОКИ                                      │ AGENTS INVOLVED
─────────────────────┼────────────────────────────────────────────┼──────────────────
Campaign Launch      │ Brief → Research → Strategy → Content →    │ Strategist, SEO,
                     │ Design → Copy → Distribution → Analytics   │ Copywriter, Designer
─────────────────────┼────────────────────────────────────────────┼──────────────────
Content Pipeline     │ Topic → Research → Outline → Draft →       │ Content Strategist,
                     │ Edit → Visual → SEO → Publish → Repurpose │ Writer, Designer, SEO
─────────────────────┼────────────────────────────────────────────┼──────────────────
Client Onboarding    │ Extract context → Fill modules →           │ Meta agents,
                     │ Configure agents → Test → Deploy           │ Dev team
─────────────────────┼────────────────────────────────────────────┼──────────────────
Skill Creation       │ Spec → Design → Build → Verify → Deploy   │ Skill Factory,
                     │                                            │ Dev team
─────────────────────┼────────────────────────────────────────────┼──────────────────
Competitive Intel    │ Monitor → Collect → Analyze → Report →     │ MI Analyst,
                     │ Recommend → Update strategy                │ Strategist
```

Кожен процес = orchestration skill який координує інших агентів.

### Стандартні output templates:

```
OUTPUT TYPE          │ ФОРМАТ                │ ANTHROPIC COMPATIBILITY
─────────────────────┼───────────────────────┼──────────────────────────
Analytical Report    │ Structured markdown   │ Artifact (markdown) або
                     │ з confidence scores   │ File Creation (docx/pdf)
─────────────────────┼───────────────────────┼──────────────────────────
Creative Copy        │ Markdown з варіантами │ Artifact (markdown) або
                     │ + brand voice rubric  │ inline response
─────────────────────┼───────────────────────┼──────────────────────────
Data Dashboard       │ JSON → React/HTML     │ Artifact (React/HTML)
                     │                       │ або File Creation (xlsx)
─────────────────────┼───────────────────────┼──────────────────────────
Presentation         │ Structured outline    │ File Creation (pptx)
                     │ → slide content       │ або Claude in PowerPoint
─────────────────────┼───────────────────────┼──────────────────────────
Plan/Strategy        │ Structured markdown   │ Artifact або File Creation
                     │ з evidence grades     │ (docx)
─────────────────────┼───────────────────────┼──────────────────────────
Handoff Package      │ JSON з schema         │ Internal (IPC/file system)
                     │                       │ not user-facing
```

---

## 6. ФАЗИ ПОБУДОВИ

```
ФАЗА 0 — FOUNDATION          (2-3 сесії)
├── 00A: Skill Standard + Taxonomy Matrix
└── 00B: Evaluation + Handoff + Output Templates + Process Templates

ФАЗА 1 — ANALYSIS            (4-6 сесій)
├── 01:  Anthropic official skills
├── 02:  Claude system prompts (DONE)
├── 02B: Non-Claude prompts (Manus, Cursor, Bolt, Lovable, Replit)
├── 07A: Auto-inventory 200 repos
├── 07B: Deep analysis через evaluation framework (батчами)
└── 07C: Synthesis → coverage + tasks + standard updates

ФАЗА 2 — CONTEXT             (1-2 сесії)
├── 08A: Context Module Architecture
└── 08B: Extraction Process Design

ФАЗА 3 — FACTORY             (2-3 сесії)
├── 05:  Build Skill Factory
└── 06:  Validate on 5 test skills

ФАЗА 4 — DEV TEAM            (1-2 сесії)
├── 09A: Generate dev/ops skills
└── 09B: Dev team validates factory

ФАЗА 5 — DOMAIN SKILLS       (5-10 сесій)
└── 10:  Batch generation (factory + dev team)

ФАЗА 6 — INTEGRATION         (2-3 сесії)
└── 11:  End-to-end testing
```

### Залежності:

```
ФАЗА 0 ──→ ФАЗА 1 (evaluation framework як лінза для аналізу)
ФАЗА 0 ──→ ФАЗА 2 (standard визначає формат context modules)
ФАЗА 0 + 1 + 2 ──→ ФАЗА 3 (factory використовує все)
ФАЗА 3 ──→ ФАЗА 4 (factory генерує dev team)
ФАЗА 3 + 4 ──→ ФАЗА 5 (factory + dev team = конвеєр)
ФАЗА 5 ──→ ФАЗА 6 (integration testing)
```

---

## 7. KNOWLEDGE BASE (що вже є)

### Власні артефакти:
```
├── ЯКОМАНДА Agent Prompt System v1.0    (52 блоки, Decision Matrix, Bias Catalog)
├── Marketing Chain v3.0                 (14 ланок, frameworks, evidence grades)
├── MECE Marketing Matrix v5             (позиції, департаменти)
├── MECE Claude Ecosystem Map            (інструменти, комбінації, JTBD)
├── NanoClaw Architecture                (container, IPC, CLAUDE.md, groups)
├── skill-architect skill                (формат, cognitive patterns, quality)
├── prompt-enhancer skill                (вразливості, detection, task types)
├── Когнітивні моделі                    (Аристотель, MECE, thinking frameworks)
```

### Anthropic references (у repos):
```
├── Anthropic Cookbook                    (офіційні рецепти і патерни)
├── Claude Agent SDK docs                (API контракти, agent patterns)
├── Claude Code architecture             (skill format, sub-agents, .claude/)
├── Claude Code system prompts           (повний production prompt)
├── Official plugins                     (marketing, financial, knowledge-work)
```

### External references (у repos):
```
├── 200+ repos                           (skills, MCP servers, frameworks, prompts)
├── Leaked system prompts                (Manus, Cursor, Bolt, Lovable, Replit)
├── Custom skill architects              (інші підходи до створення скілів)
```

### Завершені дослідження:
```
├── TASK-02 Claude system prompts        (DONE — claude_prompts_analysis.md)
├── [інші завершені таски якщо є]
```

---

## 8. DESIGN PRINCIPLES

1. **MECE everywhere** — жодних перетинів, жодних пропусків
2. **Anthropic-native** — працює через Claude Code, Claude.ai, NanoClaw, Cowork
3. **Standard-first** — спочатку стандарт, потім контент
4. **Evidence-graded** — кожне твердження має evidence grade з Chain v3
5. **Vulnerability-aware** — кожен агент має захист від LLM-specific помилок
6. **Context-fed** — агенти не працюють у вакуумі, вони живляться контекстом
7. **Handoff-native** — агенти спілкуються через формальні контракти
8. **Progressive disclosure** — SKILL.md < 500 рядків, деталі у references/
9. **Write from scratch** — чуже досліджуємо для патернів, пишемо своє
10. **Bootstrap spiral** — мінімальне ядро → розширення → валідація → ітерація
