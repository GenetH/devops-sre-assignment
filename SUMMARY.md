# SUMMARY

This repository includes five key deliverables focused on production. Together, they show an SRE mindset across **observability**, **configuration automation**, **incident response**, **disaster recovery**, and **container security**, organized as required by the assignment structure.

## Reliability goals 

* **User impact first:** alerts connect to page/warn/ticket; dashboards focus on latency (P95/P99), error rate, and saturation.
* **Safety in change:** staged rollouts, health checks, immutable artifacts, and quick rollback options.
* **Defense in depth:** least-privilege access, encrypted secrets, network segmentation, and auditability.
* **Operate to learn:** incident templates guide blameless postmortems and clear follow-ups.

---

## Task 1 - Monitoring, Observability & Alerting

* **Design:** Prometheus + Alertmanager + Grafana. Capable of high availability with dual scrapers and optional remote writing to a long-term store.
* **What’s monitored:** host metrics (CPU, memory, disk usage), containers, and application metrics (RPS, 5xx rate, latency histograms).
* **Alert policy:**
  
  * Page: InstanceDown, 5xx > 5% over 10 minutes, disk usage < 4 hours remaining.
  * Warn: P95 > 500ms over 10 minutes, high CPU/memory usage for 10 minutes.
  * SLO burn (99.9%): fast (5 minutes at 14.4×) → page; slow (1 hour at 6×) → ticket.
* **Ops:** dashboards monitor service health; alert storms are avoided through inhibition; configurations can be reloaded.

## Task 2 - Configuration Management & Scalable Production Deployment

* **Tooling:** Ansible with inventories, roles, and secured group variables.
* **Security & hardening:** SSH key-only access, root login disabled, UFW set to default-deny, fail2ban, time synchronization, auditd, and pinned SSH ciphers/MACs.
* **Deployments:** rolling serial waves with health checks; Docker runtime installed and pinned; systemd-managed application service.
* **Idempotency:** declarative modules; handlers only trigger on changes; --check and linting in CI.

## Task 3 - Incident Management & Reliability Governance

* **IR plan:** roles (IC/Comms/Owner), communication flow (Slack and status page), severity levels, paging rules, and a schedule for stakeholder updates.
* **Runbook (example):** DB outage / API latency—detect, triage, mitigate (traffic shed/circuit breaker), recover, verify.
* **Postmortem:** timeline, root cause, contributing factors, impact, and corrective actions with assigned owners and dates; learning items are recorded.

## Task 4 - Disaster Recovery & Backup Automation

* **Backups:** backup.sh script (tar, compress, optional AES-GCM encrypt, checksum, manifest), scheduled with retention.
* **Verification:** verifybackup.py checks SHA-256 and archive readability.
* **Restore:** restore.sh supports restoring the latest or a specific point and accommodates encrypted artifacts.
* **RPO/RTO:** 15 to 60 minutes RPO based on data class; less than 30 minutes to restore the app and under 2 hours for a full host recovery.
* **Storage:** S3 (with versioning and lifecycle) or NFS; secrets stored outside of version control systems; optional copy across regions.

## Task 5 - Container Security & Compliance Automation

* **CI gates:** image build followed by vulnerability scan, policy enforcement, signing/attestation, and deployment if the image is clean.
* **Blocks:** critical or high CVEs or policy violations will fail the pipeline. Reports are visible in the CI UI and Slack.
* **Supply chain:** uses immutable tags and digests; optional signature verification at deployment time.

## How to validate locally (quick)

* **Task 1:** run `docker compose up -d` in task1-monitoring/; open Prometheus (9090) and Grafana (3000). Stop the node-exporter to trigger InstanceDown and see alerts.
* **Task 2:** run `ansible-playbook -i inventory/prod.ini site.yml --check` and then apply; check the status of the application with `systemctl status <app>`.
* **Task 4:** execute `scripts/backup.sh`, then run `verifybackup.py` and `restore.sh` to the /tmp/restore directory.

### Final note

Each task contains a README that details the setup, assumptions, and reasoning behind thresholds, policies, and safeguards, supporting the assignment’s focus on clarity, maintainability, and real-world reliability.