# Task 4: Disaster Recovery & Backup Automation

This setup includes automated, verifiable backups with safe restore and clear RPO/RTO targets. It includes:
- `scripts/backup.sh` — scheduled backups with rotation (S3 or local)
- `scripts/restore.sh` — verified restores (files or Postgres)
- `scripts/verifybackup.py` — integrity verification (checksum and optional tar test)
- `architecturediagram.png` — data flow, retention, and restore path

## RPO / RTO
- **RPO:** 15 minutes for files, 1 hour for the database. This can be changed using cron or scheduler.
- **RTO:** 30 minutes or less for a single-service restore; 2 hours or less for a full stack, assuming infrastructure is available.

## Backup Frequency & Retention
- Files: every 15 minutes for critical configuration or state, kept for 14 days
- Database: hourly full logical dump (adjust based on your size), kept for 14 days
- Nightly copy to lower-cost storage class, default is `STANDARD_IA`
> Change `RETENTION_DAYS` and your bucket lifecycle policies if preferred.

## Storage Strategy
- Primary: **S3** with server-side encryption, default is SSE-S3, KMS is supported.
- Secondary (optional): local or NFS mount for quick onsite restores.
- Filenames: `backup_<tag>_<UTC-TIMESTAMP>.tar.gz[.age|.enc]` and `<same>.sha256`

## Encryption & Access Control
- **At rest:** S3 with SSE-S3 or SSE-KMS using `S3_SSE_KMS_KEY_ID`
- **Optional client-side:** `ENCRYPTION=age` (recommended) or `openssl`
- **IAM:** use least privilege, including `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, and optional `s3:DeleteObject` for retention
- Secrets shared through environment variables, no secrets in Git.

## Verification & Alerting
- Nightly `verifybackup.py` runs to check the latest backup checksum and tar integrity for local backups.
- Export the exit code for monitoring with a Node Exporter textfile collector example:
  ```bash
  /usr/local/bin/verifybackup_env.sh || true
```