---
description: Manual backup — git commit + push + DB dump
---

Run manual backup:

1. Run DB backup: `bash shared/scripts/backup-db.sh`
2. Stage changes: `git add groups/ shared/ .claude/ backups/`
3. Commit: `git commit -m "chore: manual backup {date}"`
4. Push: `git push origin main`
5. Report what was backed up
