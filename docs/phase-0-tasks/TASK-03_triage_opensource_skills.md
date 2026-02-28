# TASK-03: Швидкий Triage Open-Source Marketing Skills

## МЕТА
НЕ адаптувати чужі скіли. Витягти ТІЛЬКИ:
- Чеклісти задач (що люди очікують від кожного типу агента)
- Edge cases (які помилки автори вже зустріли)
- Output formats (що юзери хочуть бачити на виході)

Бюджет часу: 2-3 години максимум. Швидкість > глибина.

## КОНТЕКСТ
Ми пишемо 77 маркетингових agent skills З НУЛЯ.
Чужі скіли — не основа для fork, а джерело чужого досвіду помилок.
"Стоячи на плечах" — бачити що інші вже зламали.

## INPUT FILES
```
git clone https://github.com/coreyhaines31/marketingskills.git
git clone https://github.com/BrianRWagner/ai-marketing-skills.git
git clone https://github.com/SpillwaveSolutions/running-marketing-campaigns-agent-skill.git
```
+ будь-які інші marketing/AI agent skill репо з GitHub з >10 зірок.

Швидкий пошук:
```bash
# Пошук релевантних репо (переглянь топ-15-20 за зірками)
# Теми: "marketing agent skills", "ai marketing prompts", 
#        "claude skills marketing", "ai agent marketing"
```

## ЗАДАЧА

### Крок 1: Швидка інвентаризація (30 хв)
Переглянь ВСІ знайдені репо. Для кожного:
```
REPO: [назва]
STARS: [кількість]
SKILLS_COUNT: [скільки скілів]
QUALITY: [HIGH | MED | LOW — за 30 секунд оцінки]
DOMINATED_BY: [analytical | generative | transformational | mix]
```
Відсортуй за QUALITY. Далі працюй ТІЛЬКИ з HIGH і MED.

### Крок 2: Task Extraction (1.5 год)
Для КОЖНОГО скіла з HIGH/MED репо витягни ТІЛЬКИ:

```
SKILL: [назва]
AGENT_TYPE: [SEO | Email | Content | Analytics | Strategy | Social | Ads | інше]
TASK_CHECKLIST:
  - [конкретна дія яку агент виконує]
  - [конкретна дія]
  - ...
EDGE_CASES_FOUND:
  - [помилка/обмеження яке автор передбачив]
  - ...
OUTPUT_FORMAT: [що юзер отримує — report? table? copy? plan?]
```

НЕ ЧИТАЙ повний промпт. Скануй за 2-3 хвилини на скіл.

### Крок 3: Зведена таблиця по типах агентів (30 хв)
Згрупуй знайдене за типами:

```
AGENT_TYPE: SEO
COMBINED_TASK_CHECKLIST (з усіх скілів):
  - [ ] Technical audit (crawlability, speed, mobile)
  - [ ] Keyword research (volume, difficulty, intent)
  - [ ] Content gap analysis
  - [ ] Competitor backlink analysis
  - [ ] On-page optimization recommendations
  - [ ] ...
COMBINED_EDGE_CASES:
  - Сайт на JavaScript (crawling issues)
  - Мультимовний сайт
  - ...
COMMON_OUTPUT_FORMAT: [що більшість дають на виході]
```

Зроби для КОЖНОГО типу агента який знайдеш.

### Крок 4: Mapping до наших 77 позицій (30 хв)
Які з наших 77 позицій ПОКРИТІ чужими скілами (хоча б частково)?
Які НЕ ПОКРИТІ взагалі (= ніхто не робив, ми перші)?

```
COVERAGE:
  COVERED (є чужі скіли): [список позицій]
  PARTIALLY_COVERED: [список]
  NOT_COVERED (ми перші): [список]
  
NOT_COVERED — це де ми маємо бути ОСОБЛИВО УВАЖНИМИ,
бо немає чужого досвіду помилок.
```

## OUTPUT
Один файл: `opensource_skills_triage.md`
Структура:
1. Repo Inventory (крок 1)
2. Per-Skill Task Extraction (крок 2) — можна скорочено
3. Combined Task Checklists by Agent Type (крок 3) — НАЙВАЖЛИВІШЕ
4. Coverage Mapping (крок 4)

## QUALITY GATES
- [ ] Мінімум 15 скілів протріажено
- [ ] Task checklists згруповані за типами агентів
- [ ] Edge cases записані (не проігноровані)
- [ ] Coverage mapping зроблений відносно наших 77 позицій
- [ ] Весь процес зайняв НЕ БІЛЬШЕ 3 годин
