# VPS Migration Guide

## Prerequisites
- Ubuntu 22.04+ or Debian 12+
- Node.js 20+
- Docker or compatible container runtime
- Git
- 2GB+ RAM recommended

## Step 1: Clone Repository
```bash
ssh deploy@your-vps
git clone https://github.com/tabakua32/digital-office-engine.git
cd digital-office-engine
npm install
npm run build
```

## Step 2: Environment Setup
```bash
cp config/env-template .env
# Edit .env with your tokens:
nano .env
# Sync to container env:
mkdir -p data/env && cp .env data/env/env
```

## Step 3: Container Setup
```bash
# Build agent container
cd container && bash build.sh && cd ..
```

## Step 4: systemd Service
```bash
sudo cp infrastructure/systemd/digital-office.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable digital-office
sudo systemctl start digital-office
```

## Step 5: Cron Jobs
```bash
crontab -e
# Add:
*/15 * * * * $PROJECT_DIR/shared/scripts/sync-github.sh >> $PROJECT_DIR/shared/logs/sync.log 2>&1
0 3 * * * $PROJECT_DIR/shared/scripts/backup-db.sh >> $PROJECT_DIR/shared/logs/backup.log 2>&1
0 * * * * $PROJECT_DIR/shared/scripts/gdrive-sync.sh >> $PROJECT_DIR/shared/logs/gdrive.log 2>&1
```

## Step 6: Verify
```bash
# Check service
sudo systemctl status digital-office

# Check logs
journalctl -u digital-office -f

# Health check
bash shared/scripts/health-check.sh

# Test Telegram bot
# Send message to your bot
```

## Sync Strategy
```
PC (development) ──push──→ GitHub ←──pull── VPS (production)
                                    ↑
VPS agents write to groups/*/memory/ and groups/*/output/
  → VPS pushes these → PC pulls
```

Rule: PC pushes code changes. VPS pushes agent output. GitHub is source of truth.

## Rollback
```bash
sudo systemctl stop digital-office
git log --oneline -10  # find good commit
git reset --hard <commit>
npm install && npm run build
sudo systemctl start digital-office
```
