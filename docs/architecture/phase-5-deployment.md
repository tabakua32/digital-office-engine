# NanoClaw OS — Генеральний Архітектурний План

**Фаза 5: DEPLOYMENT, SECURITY & EVOLUTION**

**Version**: 1.0
**Date**: 2026-02-28
**Status**: Кінцевий дизайн
**Залежності**: Фази 1-4 (повна архітектура)

---

## 5.1 SCOPE ФАЗИ 5

```
Фази 1-4 відповіли: "ЩО система робить і ЯК працює?"
Фаза 5 відповідає: "ЯК деплоїти, захищати, масштабувати та розвивати?"

Ця фаза покриває:
├── Docker deployment architecture
├── Secret management (API keys, tokens, sessions)
├── Backup & disaster recovery
├── Monitoring & alerting
├── Security audit checklist
├── Scaling strategy
├── Operational runbooks
└── Quarterly roadmap Q1-Q4 2026
```

---

## 5.2 DOCKER DEPLOYMENT ARCHITECTURE

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  DEPLOYMENT TOPOLOGY                                               ║
║  ════════════════════                                              ║
║                                                                    ║
║  VPS (1 сервер per NanoClaw instance):                             ║
║                                                                    ║
║  ┌────────────────────────────────────────────────────────────┐  ║
║  │  Docker Host (Ubuntu 22.04+)                                  │  ║
║  │                                                                │  ║
║  │  ┌─────────────────────────────────┐                         │  ║
║  │  │ nanoclaw-core (always running)   │                         │  ║
║  │  │ ├── telegram.ts (Bot API)        │                         │  ║
║  │  │ ├── telegram-user.ts (MTProto)   │                         │  ║
║  │  │ ├── channel-coordinator.ts       │                         │  ║
║  │  │ ├── container-runner.ts          │                         │  ║
║  │  │ ├── ipc-watcher.ts              │                         │  ║
║  │  │ ├── task-scheduler.ts           │                         │  ║
║  │  │ └── sync.sh (git puller)        │                         │  ║
║  │  └─────────────────────────────────┘                         │  ║
║  │                                                                │  ║
║  │  ┌────────────┐ ┌────────────┐ ┌────────────┐               │  ║
║  │  │ agent-001  │ │ agent-002  │ │ agent-N    │               │  ║
║  │  │ (ephemeral)│ │ (ephemeral)│ │ (ephemeral)│               │  ║
║  │  └────────────┘ └────────────┘ └────────────┘               │  ║
║  │  ↑ spawned on demand, destroyed after task                    │  ║
║  │                                                                │  ║
║  │  Volumes:                                                      │  ║
║  │  ├── /data/canonical-store/  (Git repo, persistent)           │  ║
║  │  ├── /data/sqlite/           (SQLite DBs, persistent)         │  ║
║  │  ├── /data/ipc/              (IPC files, ephemeral)           │  ║
║  │  ├── /data/logs/             (app logs, rotated)              │  ║
║  │  └── /data/backups/          (automated backups)              │  ║
║  │                                                                │  ║
║  └────────────────────────────────────────────────────────────┘  ║
║                                                                    ║
║  DOCKER COMPOSE STRUCTURE:                                         ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  services:                                                          ║
║    nanoclaw-core:                                                   ║
║      image: nanoclaw:latest                                         ║
║      restart: unless-stopped                                        ║
║      env_file: .env                                                 ║
║      volumes:                                                       ║
║        - ./data:/data                                               ║
║        - /var/run/docker.sock:/var/run/docker.sock  ← DinD         ║
║                                                                    ║
║      ⚠️ DOCKER SOCKET SECURITY TRADEOFF:                             ║
║      ├── docker.sock mount = фактично root доступ to host            ║
║      ├── ПОТРІБНО: core spawns agent containers via Docker API       ║
║      ├── MITIGATION (Phase S1):                                      ║
║      │   Option A: Docker API через TCP + TLS mutual auth           ║
║      │   Option B: Podman (rootless, немає daemon socket)          ║
║      │   Option C: User namespace remapping + seccomp + AppArmor   ║
║      ├── CURRENT (Phase S0): Прийнятний ризик для single-owner   ║
║      │   deployment, owner = admin = operator                       ║
║      └── Agent containers: NO docker.sock (§5.6 checklist)           ║
║                                                                    ║
║      ports:                                                         ║
║        - "127.0.0.1:3000:3000"  ← health endpoint only            ║
║      healthcheck:                                                   ║
║        test: ["CMD", "curl", "-f", "http://localhost:3000/health"] ║
║        interval: 30s                                                ║
║        timeout: 5s                                                  ║
║        retries: 3                                                   ║
║      deploy:                                                        ║
║        resources:                                                   ║
║          limits:                                                    ║
║            memory: 1G                                               ║
║            cpus: '2.0'                                              ║
║                                                                    ║
║  AGENT CONTAINER SPEC:                                              ║
║  ──────────────────────                                             ║
║                                                                    ║
║  Spawned by container-runner.ts:                                    ║
║  ├── Image: nanoclaw-agent:latest (minimal Node.js runtime)        ║
║  ├── Memory limit: 256MB per container                              ║
║  ├── CPU limit: 0.5 CPU per container                               ║
║  ├── Network: limited (only Claude API + allowed MCP hosts)        ║
║  ├── Filesystem: read-only except /ipc/ mount                      ║
║  ├── Max concurrent: 5 containers (configurable)                   ║
║  ├── Timeout: 300s (5 min) → kill                                   ║
║  ├── Mounts:                                                        ║
║  │   ├── /data/canonical-store/companies/{name}/: read-only        ║
║  │   ├── /data/ipc/{group}/: read-write                            ║
║  │   └── /data/canonical-store/foundation/: read-only              ║
║  └── NO access to: .env, docker.sock, user-session.enc, SQLite    ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.3 SECRET MANAGEMENT

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  SECRETS INVENTORY                                                  ║
║  ═════════════════                                                  ║
║                                                                    ║
║  ┌──────────────────┬──────────────┬─────────────────────────┐  ║
║  │ Secret              │ Storage       │ Access                    │  ║
║  ├──────────────────┼──────────────┼─────────────────────────┤  ║
║  │ CLAUDE_API_KEY      │ .env          │ Core only, NOT containers │  ║
║  │ TELEGRAM_BOT_TOKEN  │ .env          │ Core only                 │  ║
║  │ NANOCLAW_SESSION_KEY│ .env          │ Core only (AES-256-GCM)   │  ║
║  │ user-session.enc    │ /data/secrets │ Core only, encrypted      │  ║
║  │ GIT_SSH_KEY         │ /data/secrets │ Core + sync.sh only       │  ║
║  │ MCP_*_API_KEYS      │ .env          │ Per MCP server config     │  ║
║  └──────────────────┴──────────────┴─────────────────────────┘  ║
║                                                                    ║
║  PRINCIPLES:                                                        ║
║  ├── Secrets НІКОЛИ не потрапляють у Git                           ║
║  ├── Secrets НІКОЛИ не передаються в agent containers               ║
║  ├── .env файл: chmod 600, owned by root                           ║
║  ├── user-session.enc: encrypted at rest (AES-256-GCM)             ║
║  ├── Rotation: API keys змінюються щоквартально                    ║
║  └── Audit: log access to secrets (who, when, what)                ║
║                                                                    ║
║  CONTAINER ISOLATION:                                               ║
║  ├── Containers call Claude API ЧЕРЕЗ core process (IPC)           ║
║  │   → Container writes task → Core reads → Core calls Claude      ║
║  │   → Core writes result → Container reads                        ║
║  ├── Container НІКОЛИ не має прямого доступу до Claude API         ║
║  ├── Container НІКОЛИ не бачить TELEGRAM_BOT_TOKEN                 ║
║  └── Container НІКОЛИ не бачить user-session.enc                   ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.4 BACKUP & DISASTER RECOVERY

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  BACKUP STRATEGY                                                    ║
║  ════════════════                                                   ║
║                                                                    ║
║  ┌──────────────────┬───────────────┬─────────────────────┐      ║
║  │ Що                  │ Як часто       │ Куди                  │      ║
║  ├──────────────────┼───────────────┼─────────────────────┤      ║
║  │ Canonical Store     │ Кожен commit   │ Git remote (GitHub)   │      ║
║  │ (Git repo)          │ = real-time    │ + 2nd remote (backup) │      ║
║  ├──────────────────┼───────────────┼─────────────────────┤      ║
║  │ SQLite databases    │ Щоденно o 3:00 │ /data/backups/ +      │      ║
║  │ (tasks, sessions)   │                │ remote storage        │      ║
║  ├──────────────────┼───────────────┼─────────────────────┤      ║
║  │ .env + secrets      │ При зміні      │ Encrypted backup      │      ║
║  │                     │                │ + password manager    │      ║
║  ├──────────────────┼───────────────┼─────────────────────┤      ║
║  │ Docker images       │ При build      │ Container registry    │      ║
║  ├──────────────────┼───────────────┼─────────────────────┤      ║
║  │ Logs                │ 30 днів local  │ Rotate + archive      │      ║
║  └──────────────────┴───────────────┴─────────────────────┘      ║
║                                                                    ║
║  DISASTER RECOVERY PLAN:                                            ║
║  ─────────────────────────                                          ║
║                                                                    ║
║  Scenario 1: VPS crashed                                            ║
║  ├── Time to recover: <1 год                                       ║
║  ├── Steps:                                                         ║
║  │   ① Provision new VPS                                            ║
║  │   ② Install Docker                                               ║
║  │   ③ git clone canonical-store                                    ║
║  │   ④ Restore .env from password manager                          ║
║  │   ⑤ Restore SQLite from backup                                  ║
║  │   ⑥ docker compose up                                           ║
║  └── Data loss: 0 (Git = real-time, SQLite ≤ 24 hours)            ║
║                                                                    ║
║  Scenario 2: Git repo corrupted                                     ║
║  ├── Recovery: clone from secondary remote                          ║
║  └── Data loss: 0 (dual remote)                                    ║
║                                                                    ║
║  Scenario 3: API key compromised                                    ║
║  ├── ① Rotate key immediately (Anthropic dashboard)                ║
║  ├── ② Update .env, restart core                                   ║
║  ├── ③ Audit: check cost_log.jsonl for unauthorized usage          ║
║  └── ④ Notify owner                                                ║
║                                                                    ║
║  Scenario 4: MTProto session leaked                                 ║
║  ├── ① Terminate all Telegram sessions (settings → devices)       ║
║  ├── ② Generate new session via GramJS                              ║
║  ├── ③ Encrypt with new NANOCLAW_SESSION_KEY                       ║
║  └── ④ Update .env + restart                                       ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.5 MONITORING & ALERTING

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  MONITORING LAYERS                                                  ║
║  ═════════════════                                                  ║
║                                                                    ║
║  Layer 1: HEALTH CHECK (system-level)                               ║
║  ├── HTTP /health endpoint: перевіряє core process alive           ║
║  ├── Docker healthcheck: restart if unhealthy × 3                   ║
║  ├── External monitor (UptimeRobot/Healthchecks.io):               ║
║  │   ├── Ping кожні 5 хв                                           ║
║  │   ├── Alert: Telegram notification to owner                     ║
║  │   └── Escalation: email if down > 15 min                       ║
║  └── Disk space: alert at 80% usage                                ║
║                                                                    ║
║  Layer 2: APPLICATION METRICS (NanoClaw-level)                     ║
║  ├── Requests/hour per company                                      ║
║  ├── Average response time (ms)                                     ║
║  ├── Error rate (% of failed requests)                              ║
║  ├── Active containers count                                        ║
║  ├── Cost per day/week/month (from cost_log.jsonl)                 ║
║  ├── Memory usage per company (facts.jsonl size)                   ║
║  └── Scheduled tasks execution status                               ║
║                                                                    ║
║  Layer 3: QUALITY METRICS (agent-level)                             ║
║  ├── HITL approval rate (% approved without edits)                 ║
║  ├── Timeout rate (% of HITL timeouts)                              ║
║  ├── Tool error rate (% of failed tool calls)                      ║
║  ├── Model fallback frequency                                       ║
║  └── Token usage efficiency (output/input ratio)                   ║
║                                                                    ║
║  ALERTING RULES:                                                    ║
║  ──────────────                                                     ║
║                                                                    ║
║  ┌────────────────────┬───────────────┬──────────────────┐        ║
║  │ Condition             │ Severity       │ Action              │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Core down              │ 🔴 CRITICAL   │ Auto-restart +      │        ║
║  │                        │               │ Telegram alert      │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Claude API 401        │ 🔴 CRITICAL   │ Pause + alert owner│        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Error rate > 20%      │ 🟡 WARNING    │ Telegram alert      │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Budget > 80%          │ 🟡 WARNING    │ Auto-downgrade      │        ║
║  │                        │               │ + alert              │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Disk > 80%            │ 🟡 WARNING    │ Log rotation +      │        ║
║  │                        │               │ alert                │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Container timeout     │ 🟢 INFO       │ Log + retry          │        ║
║  ├────────────────────┼───────────────┼──────────────────┤        ║
║  │ Scheduled task failed │ 🟢 INFO       │ Log + retry next    │        ║
║  └────────────────────┴───────────────┴──────────────────┘        ║
║                                                                    ║
║  ALERT DELIVERY:                                                    ║
║  ├── Primary: Telegram message to owner's main group               ║
║  ├── Secondary: Email (for extended downtime)                       ║
║  └── Dashboard: /admin/* Mini App (Phase 2, Q4)                    ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.6 SECURITY AUDIT CHECKLIST

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  SECURITY CHECKLIST (before production)                            ║
║  ══════════════════════════════════════                             ║
║                                                                    ║
║  AUTHENTICATION & ACCESS:                                           ║
║  ☐ .env file: chmod 600, owned by deploy user                     ║
║  ☐ Docker socket: accessible only by deploy user                   ║
║  ☐ SSH: key-only auth, no root login, fail2ban enabled             ║
║  ☐ VPS firewall: only 22 (SSH) + outbound HTTPS                   ║
║  ☐ No exposed ports (NanoClaw communicates via Telegram + Claude)  ║
║                                                                    ║
║  CONTAINER ISOLATION:                                               ║
║  ☐ Agent containers: no .env access                                ║
║  ☐ Agent containers: no docker.sock access                         ║
║  ☐ Agent containers: no network except Claude API whitelist        ║
║  ☐ Agent containers: read-only filesystem (except /ipc/)           ║
║  ☐ Agent containers: memory + CPU limits enforced                  ║
║  ☐ Agent containers: 5-min hard timeout                            ║
║  ☐ No cross-company data leakage (mount isolation)                 ║
║                                                                    ║
║  DATA PROTECTION:                                                   ║
║  ☐ MTProto session: encrypted at rest (AES-256-GCM)               ║
║  ☐ PII filter: no emails/phones/passwords in memory files         ║
║  ☐ Git: no secrets in repo (pre-commit hook)                       ║
║  ☐ SQLite: backed up + encrypted at rest                           ║
║  ☐ Logs: no API keys or tokens in log output                      ║
║  ☐ IPC files: cleaned up after container exit                      ║
║                                                                    ║
║  API SECURITY:                                                      ║
║  ☐ Claude API key: rotated quarterly                               ║
║  ☐ Telegram Bot token: rotated if compromised via @BotFather      ║
║  ☐ Rate limiting: per-company to prevent abuse                     ║
║  ☐ Cost alert: budget-based model downgrade cascade                ║
║  ☐ Tool validation: IPC tool inputs sanitized                      ║
║                                                                    ║
║  TELEGRAM SAFETY:                                                   ║
║  ☐ Anti-ban protocol active (Phase 2.5)                            ║
║  ☐ Risk classification enforced (🟢🟡🔴⛔)                         ║
║  ☐ HITL for HIGH risk actions                                       ║
║  ☐ BLOCKED actions never executed programmatically                  ║
║  ☐ User account: graceful degradation if unavailable                ║
║                                                                    ║
║  OPERATIONAL SECURITY:                                              ║
║  ☐ Automated backup tested (restore from scratch test)             ║
║  ☐ Disaster recovery runbook documented                             ║
║  ☐ Incident response contacts defined                               ║
║  ☐ Security updates: host OS + Docker patched monthly              ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.7 SCALING STRATEGY

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  SCALING PHASES                                                     ║
║  ══════════════                                                     ║
║                                                                    ║
║  Phase S0: SINGLE OWNER (launch)                                    ║
║  ├── 1 VPS, 1 NanoClaw instance                                    ║
║  ├── 1-3 companies                                                  ║
║  ├── VPS spec: 2 CPU, 4GB RAM, 50GB SSD — ~$20/mo                 ║
║  ├── Claude API: Tier 2 sufficient                                  ║
║  └── Bottleneck: none at this scale                                ║
║                                                                    ║
║  Phase S1: POWER USER (3-6 months)                                  ║
║  ├── 1 VPS (upgraded), 1 NanoClaw instance                          ║
║  ├── 5-10 companies                                                 ║
║  ├── VPS spec: 4 CPU, 8GB RAM, 100GB SSD — ~$40/mo                ║
║  ├── Max concurrent containers: 10 (up from 5)                     ║
║  ├── Claude API: Tier 3 (or rate-limit queue)                      ║
║  └── Bottleneck: Claude API rate limits → queueing                 ║
║                                                                    ║
║  Phase S2: MULTI-OWNER (future, 12+ months)                        ║
║  ├── Multiple VPS or Kubernetes                                     ║
║  ├── 1 NanoClaw instance PER OWNER (separate deployments)          ║
║  ├── Shared: nothing (each owner = self-contained)                  ║
║  └── Bottleneck: deployment automation                              ║
║                                                                    ║
║  IMPORTANT: NanoClaw архітектурно НЕ SaaS                          ║
║  ├── 1 owner = 1 instance = 1 deployment                           ║
║  ├── Multi-tenant NOT planned (security + simplicity + ownership)  ║
║  └── Scaling = more instances, not bigger instance                  ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.8 OPERATIONAL RUNBOOKS

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  RUNBOOK 1: INITIAL DEPLOYMENT                                     ║
║  ─────────────────────────────                                     ║
║  ① Provision VPS (Ubuntu 22.04+, 2CPU/4GB)                         ║
║  ② Install Docker + Docker Compose                                  ║
║  ③ Clone NanoClaw repo                                              ║
║  ④ Configure .env (all secrets)                                    ║
║  ⑤ Initialize canonical store (git init + structure)               ║
║  ⑥ docker compose up -d                                            ║
║  ⑦ Set Telegram bot webhook                                        ║
║  ⑧ Test: send message to bot → verify response                    ║
║  ⑨ Optionally: configure MTProto (GramJS auth flow)                ║
║  ⑩ Set up external monitoring (UptimeRobot)                        ║
║                                                                    ║
║  RUNBOOK 2: ADD NEW COMPANY                                        ║
║  ──────────────────────────                                        ║
║  ① Create Telegram group for company                                ║
║  ② Add bot to group (triggers Group Discovery Pipeline)            ║
║  ③ Choose depth level (Quick/Standard/Full)                         ║
║  ④ Review generated context files                                   ║
║  ⑤ Set budget (companies/{name}/memory/budget.json)                ║
║  ⑥ Test: send task in group → verify response                     ║
║                                                                    ║
║  RUNBOOK 3: UPDATE NANOCLAW                                        ║
║  ─────────────────────────                                          ║
║  ① git pull (latest code)                                           ║
║  ② docker compose build                                             ║
║  ③ docker compose down && docker compose up -d                     ║
║  ④ Verify: /health endpoint + send test message                    ║
║  ⑤ Monitor logs for 15 min: docker compose logs -f                 ║
║                                                                    ║
║  RUNBOOK 4: ROTATE API KEY                                          ║
║  ──────────────────────────                                         ║
║  ① Generate new key in Anthropic dashboard                          ║
║  ② Update .env: CLAUDE_API_KEY=new_key                              ║
║  ③ docker compose restart nanoclaw-core                             ║
║  ④ Verify: send test message → check response                     ║
║  ⑤ Revoke old key in Anthropic dashboard                            ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.9 QUARTERLY ROADMAP Q1-Q4 2026 (REALISTIC)

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                    ║
║  ПОТОЧНИЙ СТАН (28 лютого 2026)                                   ║
║  ══════════════════════════════                                    ║
║  ✅ Архітектура: 8 документів (Фази 0-5 + 2.5 + GDP) = ~430KB    ║
║  ✅ telegram.ts: базовий messaging, media, keyboards, commands    ║
║  ✅ Groups/Supergroups: 1 group = 1 company model                 ║
║  ✅ Scheduled reports: sendMessage to group                       ║
║  🔴 Runtime: container-runner.ts НЕ написаний                     ║
║  🔴 IPC: протокол НЕ реалізований                                ║
║  🔴 Claude SDK: інтеграція НЕ реалізована                        ║
║  🔴 Skills: жоден SKILL.md НЕ створений                          ║
║  🔴 Context modules: порожні                                      ║
║  🔴 Docker: compose НЕ готовий                                    ║
║                                                                    ║
║  РЕСУРС: 1 розробник + Claude agents як co-developers             ║
║  ESTIMATE: ~2500 LOC для MVP runtime                              ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Q1 2026 (залишок — 1 день) ← МИ ТУТ                             ║
║  ════════════════════════════════                                   ║
║  ✅ Architecture Phase 0-5: DONE (Foundation Layer завершений)     ║
║  ✅ Red Team v1-v3: all 32 consistency checks passed              ║
║  ✅ Forum Thread Hierarchy spec: Phase 0 §0.4                     ║
║  ✅ Evaluation Framework 100pt: Phase 0 §0.5                      ║
║  ✅ Basic telegram.ts: Q1 items done (Phase 2 mapping)            ║
║                                                                    ║
║  Q1 RESULT: повна архітектура + live telegram bot (basic)         ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Q2 2026 (Квітень-Червень): BUILD RUNTIME                         ║
║  ═════════════════════════════════════════                          ║
║                                                                    ║
║  КВІТЕНЬ — CORE RUNTIME (4 тижні)                                 ║
║  ─────────────────────────────────                                ║
║  Тиждень 1-2: container-runner.ts                                  ║
║  ├── Docker SDK інтеграція (spawn containers)                     ║
║  ├── Volume mounts: /skill, /context, /foundation, /output         ║
║  ├── stdout/stderr → IPC pipe                                      ║
║  ├── Timeout + cleanup (max 5 хв per container)                   ║
║  └── 🧪 Тест: docker run + echo → stdout captured                ║
║                                                                    ║
║  Тиждень 3-4: Claude SDK + 3-Layer Prompt Assembly                 ║
║  ├── @anthropic-ai/sdk інтеграція в agent-runner                  ║
║  ├── 3-Layer system prompt: Foundation + Context + Skill           ║
║  ├── effort param routing per skill manifest                      ║
║  ├── Streaming: Claude SSE → stdout → router                      ║
║  └── 🧪 Тест: "напиши текст" → Claude відповідь у container      ║
║                                                                    ║
║  ⭐ MILESTONE 1 (30 квітня): "Hello Claude"                       ║
║  User → TG message → container → Claude → response → TG          ║
║  Без HITL, без memory, один hardcoded skill.                      ║
║                                                                    ║
║  ТРАВЕНЬ — IPC + ROUTING (4 тижні)                                ║
║  ─────────────────────────────────                                ║
║  Тиждень 5-6: IPC Protocol                                        ║
║  ├── ipc.ts: container ↔ router communication                     ║
║  ├── /ipc/input.json, /ipc/output.json, /ipc/tools/               ║
║  ├── Handoff protocol (Phase 0 §0.6) JSON schema                  ║
║  ├── Error handling: timeout, crash, retry                        ║
║  └── 🧪 Тест: multi-turn conversation works                      ║
║                                                                    ║
║  Тиждень 7-8: Router + Skill Selection                            ║
║  ├── router.ts: Haiku classifier (Phase 4 Flow A §2)              ║
║  ├── Thread enrichment (thread_hierarchy.json, Phase 0 §0.4)     ║
║  ├── Skill manifest loading                                        ║
║  ├── SQLite: sessions, tasks, message_log                         ║
║  └── 🧪 Тест: routing по @mention + implicit classification      ║
║                                                                    ║
║  ⭐ MILESTONE 2 (31 травня): "Smart Router"                       ║
║  User → message → router classifies → correct skill → response   ║
║  Thread-aware routing working. SQLite persistence.                ║
║                                                                    ║
║  ЧЕРВЕНЬ — FIRST SKILLS + HITL (4 тижні)                          ║
║  ─────────────────────────────────────────                         ║
║  Тиждень 9-10: Foundation Files + First 3 Skills                   ║
║  ├── foundation/ files створені (Phase 0 §0.2 standard)          ║
║  │   ├── skill_standard.md                                         ║
║  │   ├── evaluation_framework.md                                   ║
║  │   ├── handoff_protocol.md                                       ║
║  │   └── channel_adaptors/telegram.md                              ║
║  ├── SKILL #1: meta/general-assistant (catch-all)                  ║
║  ├── SKILL #2: marketing/content/copywriter (generative)          ║
║  ├── SKILL #3: marketing/market-intelligence/analyst (analytical) ║
║  └── 🧪 Тест: кожен skill проходить evaluation ≥70/100           ║
║                                                                    ║
║  Тиждень 11-12: HITL + Streaming                                   ║
║  ├── HITL Level 1: approve/reject keyboards (Phase 2 §2.4-C)     ║
║  ├── sendMessageDraft streaming (Phase 2 §2.4-A)                  ║
║  ├── Output chunking (Phase 2 §2.6: ≤4000 chars)                 ║
║  ├── Callback routing: approve_content_001_style                  ║
║  └── 🧪 Тест: ask → draft shown → approve → final content        ║
║                                                                    ║
║  ⭐ MILESTONE 3 (30 червня): "First Company MVP"                  ║
║  GO/NO-GO: 3 skills working, HITL approval, streaming,            ║
║  thread routing, SQLite persistence. First компанія onboarded.    ║
║                                                                    ║
║  ⚠️ Q2 РИЗИКИ:                                                    ║
║  ├── Docker SDK integration complexity (~20% buffer)              ║
║  ├── Claude streaming + Telegram draft synchronization            ║
║  └── Haiku classifier accuracy for implicit routing               ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Q3 2026 (Липень-Вересень): GROW SKILLS + MEMORY                  ║
║  ════════════════════════════════════════════                       ║
║                                                                    ║
║  ЛИПЕНЬ — MEMORY + CONTEXT (4 тижні)                              ║
║  ────────────────────────────────────                              ║
║  Тиждень 13-14: Memory System (Phase 4 §4.8)                      ║
║  ├── CLAUDE.md per-agent persistent memory                        ║
║  ├── facts.jsonl: structured fact extraction                       ║
║  ├── Memory lifecycle: create → access → decay → archive          ║
║  └── 🧪 Тест: agent remembers context from previous session      ║
║                                                                    ║
║  Тиждень 15-16: Context Modules + Onboarding                      ║
║  ├── Minimum Viable Context: identity + spec + icp + voice        ║
║  ├── Extraction process: company website → Claude → modules       ║
║  ├── /onboard command: guided context filling wizard              ║
║  └── 🧪 Тест: нова компанія в групі → context заповнений         ║
║                                                                    ║
║  ⭐ MILESTONE 4 (31 липня): "Memory Works"                        ║
║  Agent learns across sessions, context modules filled.            ║
║                                                                    ║
║  СЕРПЕНЬ — SKILL FACTORY + BATCH (4 тижні)                        ║
║  ──────────────────────────────────────────                        ║
║  Тиждень 17-18: Skill Factory (Track B Ф-3)                       ║
║  ├── meta/factory skill: генерує нові skills за шаблоном          ║
║  ├── audit_skill.py: automated evaluation (Phase 0 §0.5)         ║
║  ├── Batch generation: 5 skills за раз через Batch API            ║
║  └── 🧪 Тест: factory → генерує skill → проходить eval ≥80       ║
║                                                                    ║
║  Тиждень 19-20: Content Pipeline + Scheduling                     ║
║  ├── Process template: Content Pipeline (Phase 0 §0.8)            ║
║  ├── Multi-agent Flow D: strategist → writer → SEO → publish     ║
║  ├── Cron scheduler: weekly/daily content generation              ║
║  ├── Cost tracking: budget.json per company (Phase 4 Flow J)     ║
║  └── 🧪 Тест: scheduled weekly report автоматично у потрібну тему ║
║                                                                    ║
║  ⭐ MILESTONE 5 (31 серпня): "Content Machine"                    ║
║  Multi-step content pipeline, scheduling, 10+ skills, budget.     ║
║                                                                    ║
║  ВЕРЕСЕНЬ — FORUMS + VOICE (4 тижні)                              ║
║  ────────────────────────────────────                              ║
║  Тиждень 21-22: Forum Topics Integration                          ║
║  ├── thread_hierarchy.json: auto-discovery at bot join             ║
║  ├── Dynamic topic creation: /topic [name]                        ║
║  ├── Campaign topics: auto-create/close per campaign              ║
║  ├── Thread-aware system prompt injection (Phase 0 §0.4-C)       ║
║  └── 🧪 Тест: message у "✍️ Контент" → copywriter skill          ║
║                                                                    ║
║  Тиждень 23-24: Voice I/O + Prompt Caching                        ║
║  ├── Voice input: Groq Whisper STT (Phase 2 §2.4-D)              ║
║  ├── Voice output: Piper TTS (self-hosted, free)                  ║
║  ├── Prompt caching optimization: Layer 1+2 combined              ║
║  ├── Cache hit tracking + cost reduction metrics                  ║
║  └── 🧪 Тест: voice message → transcription → response → TTS     ║
║                                                                    ║
║  ⭐ MILESTONE 6 (30 вересня): "Intelligence Layer"                ║
║  GO/NO-GO: 15+ skills, forum routing, voice, caching, factory.   ║
║  Готовність для 2-3 компаній одночасно.                           ║
║                                                                    ║
║  ⚠️ Q3 РИЗИКИ:                                                    ║
║  ├── Multi-agent pipelines: cascade error propagation              ║
║  ├── GramJS postponed to Q4 (focus on core value first)           ║
║  └── Voice quality: Piper vs ElevenLabs tradeoff                  ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Q4 2026 (Жовтень-Грудень): SCALE + PRODUCTION                   ║
║  ═══════════════════════════════════════════                        ║
║                                                                    ║
║  ЖОВТЕНЬ — MULTI-COMPANY + MTPROTO (4 тижні)                     ║
║  ─────────────────────────────────────────────                    ║
║  Тиждень 25-26: Multi-Company Scaling                              ║
║  ├── 3-5 компаній одночасно                                        ║
║  ├── Resource isolation: per-company containers + budget           ║
║  ├── Group Discovery Pipeline (GDP) activation                    ║
║  ├── Compaction API для нескінченних розмов                        ║
║  └── 🧪 Тест: 3 companies × 5 concurrent requests                ║
║                                                                    ║
║  Тиждень 27-28: MTProto (Phase 2.5)                                ║
║  ├── GramJS integration: userbot container                         ║
║  ├── Channel auto-monitoring: competitors, audience               ║
║  ├── Group stats scraping (member demographics)                   ║
║  ├── Anti-ban: rate limits, session management                    ║
║  └── 🧪 Тест: passive data collection without ban                ║
║                                                                    ║
║  ⭐ MILESTONE 7 (31 жовтня): "Multi-Tenant"                      ║
║  3+ companies, MTProto passive intelligence working.              ║
║                                                                    ║
║  ЛИСТОПАД — CHANNELS + CONNECTORS (4 тижні)                      ║
║  ────────────────────────────────────────────                      ║
║  Тиждень 29-30: Channel Publishing + Connectors                   ║
║  ├── telegram-mcp: channel publishing skill (Phase 2 §2.4-E)     ║
║  ├── Channel content scheduling: post → approve → schedule        ║
║  ├── Stories publishing via Bot API 9.3                            ║
║  ├── LinkedIn connector: basic content cross-posting              ║
║  └── 🧪 Тест: content pipeline → auto-post to channel            ║
║                                                                    ║
║  Тиждень 31-32: Dev Team Skills + Security                        ║
║  ├── dev-ops/auditor skill: code review automation                ║
║  ├── dev-ops/security skill: checklist validation                 ║
║  ├── Full security audit (Phase 5 §5.6 checklist)                ║
║  ├── Session encryption: user-session.enc (Phase 5 §5.4)         ║
║  └── 🧪 Тест: security checklist ≥90% green                      ║
║                                                                    ║
║  ⭐ MILESTONE 8 (30 листопада): "Channel Machine"                 ║
║  Auto-publishing, cross-platform, dev-ops skills, secure.        ║
║                                                                    ║
║  ГРУДЕНЬ — POLISH + LAUNCH (4 тижні)                              ║
║  ────────────────────────────────────                              ║
║  Тиждень 33-34: Domain Skills Completion                           ║
║  ├── Batch generate remaining skills (factory + Batch API)        ║
║  ├── Target: 25-30 skills covering all 6 domains                  ║
║  ├── Vector memory: pgvector/FTS5 (1000+ facts)                   ║
║  └── 🧪 Тест: coverage matrix ≥80% filled                        ║
║                                                                    ║
║  Тиждень 35-36: Documentation + Validation                        ║
║  ├── User guide: owner onboarding manual                          ║
║  ├── Architecture update: sync all phases with reality            ║
║  ├── End-to-end integration tests: all 10 flows (A-J)            ║
║  ├── Cost report: actual vs projected per company                 ║
║  └── 🧪 Тест: new owner can onboard without developer help       ║
║                                                                    ║
║  ⭐ MILESTONE 9 (31 грудня): "Production Ready v1.0"              ║
║  GO/NO-GO: 25+ skills, 3+ companies, all flows tested,           ║
║  security audit green, documentation complete.                     ║
║  Ready for Phase S1: second owner onboarding.                      ║
║                                                                    ║
║  ⚠️ Q4 РИЗИКИ:                                                    ║
║  ├── GramJS anti-ban: Telegram може заблокувати userbot           ║
║  ├── Mini Apps POSTPONED to 2027 (not critical for v1.0)          ║
║  ├── LinkedIn API: обмежений доступ без premium                   ║
║  └── Email connector POSTPONED to 2027 (не пріоритет)             ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  SHIFTED TO 2027 (scope cut для реалістичності)                   ║
║  ═══════════════════════════════════════════════                    ║
║  ├── Mini Apps (dashboard, content calendar, funnel builder)      ║
║  ├── Email connector (newsletter integration)                     ║
║  ├── WhatsApp connector (secondary channel)                       ║
║  ├── Paid subscriptions (Stars recurring)                         ║
║  ├── Phase S2: multi-owner SaaS model                             ║
║  └── Business Account features (greeting/away messages)           ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  DEPENDENCY CHAIN (критичний шлях)                                ║
║  ══════════════════════════════════                                ║
║                                                                    ║
║  container-runner → Claude SDK → IPC → Router → Skills            ║
║       (Apr W1)     (Apr W3)   (May W5) (May W7) (Jun W9)         ║
║                                                    ↓               ║
║                                   HITL → Memory → Factory          ║
║                                (Jun W11) (Jul W13) (Aug W17)      ║
║                                                    ↓               ║
║                               Pipeline → Forums → Voice           ║
║                              (Aug W19) (Sep W21) (Sep W23)        ║
║                                                    ↓               ║
║                              Multi-co → MTProto → Channels        ║
║                             (Oct W25) (Oct W27) (Nov W29)         ║
║                                                    ↓               ║
║                                  Batch Skills → Launch v1.0       ║
║                                  (Dec W33)     (Dec W36)          ║
║                                                                    ║
║  ⚠️ BUFFER: 2 тижні slack вбудовані у кожен квартал               ║
║  (фактичних робочих тижнів = 36 / 40 календарних = 10% buffer)   ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5.10 UPDATES TO PREVIOUS PHASES

```
╔══════════════════════════════════════════════════════════════════╗
║  PHASE 5 DELTAS TO PHASE 1:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Docker deployment topology specified                             ║
║  + VPS requirements defined (2CPU/4GB minimum)                     ║
║  + ~2500 LOC estimate validated by container arch                  ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 5 DELTAS TO PHASE 2/2.5:                                   ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Webhook setup in deployment runbook                              ║
║  + MTProto session security fully specified                         ║
║  + Anti-ban → security checklist integration                       ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 5 DELTAS TO PHASE 3:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + API key rotation runbook                                         ║
║  + Rate limit → scaling strategy connection                        ║
║  + Cost monitoring → alerting integration                           ║
║                                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  PHASE 5 DELTAS TO PHASE 4:                                       ║
║  ──────────────────────────                                        ║
║                                                                    ║
║  + Memory files backup strategy                                     ║
║  + IPC files cleanup on container exit                              ║
║  + Cost log → monitoring integration                                ║
║  + Scheduled tasks → operational monitoring                         ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*Фаза 5 завершена. Усі 5 фаз архітектурного документу + 2 додатки (2.5, GDP) = ПОВНА АРХІТЕКТУРА.*
