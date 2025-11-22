# Task 4 — Disaster Recovery & Backup Automation

This implements automated, verifiable backups with safe restore and clear RPO/RTO targets. Includes:
- `scripts/backup.sh` – scheduled backups with rotation (S3 or local)
- `scripts/restore.sh` – verified restores (files or Postgres)
- `scripts/verifybackup.py` – integrity verification (checksum and optional tar test)
- `architecturediagram.png` – data flow, retention, restore path

## RPO / RTO
- **RPO:** 15 minutes (files) / 1 hour (DB) – configurable via cron/scheduler
- **RTO:** ≤ 30 minutes for single-service restore; ≤ 2 hours for full stack (assumes infra available)

## Backup Frequency & Retention
- Files: every 15 minutes (critical config/state), retain 14 days
- DB: hourly full logical dump (tune to your size), retain 14 days
- Nightly copy to lower-cost storage class (`STANDARD_IA` by default)
> Adjust `RETENTION_DAYS` and your bucket lifecycle policies if preferred.

## Storage Strategy
- Primary: **S3** with server-side encryption (SSE-S3 by default, KMS supported)
- Secondary (optional): local/NFS mount for rapid on-site restores
- Filenames: `backup_<tag>_<UTC-TIMESTAMP>.tar.gz[.age|.enc]` + `<same>.sha256`

## Encryption & Access Control
- **At rest:** S3 SSE-S3 or SSE-KMS (`S3_SSE_KMS_KEY_ID`)
- **Optional client-side:** `ENCRYPTION=age` (recommended) or `openssl`
- **IAM:** least privilege (`s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, optional `s3:DeleteObject` for retention)
- Secrets provided via env (no secrets in Git)

## Verification & Alerting
- Nightly `verifybackup.py` runs to validate the latest backup checksum (and tar integrity for local).
- Export exit code to monitoring (Node Exporter textfile collector example):
  ```bash
  /usr/local/bin/verifybackup_env.sh || true
