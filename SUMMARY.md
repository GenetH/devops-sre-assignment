# SUMMARY

This repository contains five production-focused deliverables that together demonstrate an SRE mindset across **observability**, **configuration automation**, **incident response**, **disaster recovery**, and **container security** organized exactly as required in the assignment structure. 

## Reliability goals (cross-cutting)

* **User impact first:** alerts map to page/warn/ticket; dashboards center on latency (P95/P99), error rate, and saturation.
* **Safety in change:** staged rollouts, health gates, immutable artifacts, and fast rollback paths.
* **Defense in depth:** least-privilege access, encrypted secrets, network segmentation, and auditability.
* **Operate to learn:** incident templates drive blameless postmortems and concrete follow-ups.

---

## Task 1 — Monitoring, Observability & Alerting

* **Design:** Prometheus + Alertmanager + Grafana. HA-capable (dual scrapers, optional remote_write to long-term store).
* **What’s monitored:** host (CPU, memory, disk runout), containers, and app (RPS, 5xx rate, latency histograms).
* **Alert policy:**

  * Page: InstanceDown, 5xx > 5% 10m, disk runout < 4h.
  * Warn: P95 > 500ms 10m, high CPU/memory 10m.
  * SLO burn (99.9%): fast (5m @ 14.4×) → page; slow (1h @ 6×) → ticket.
* **Ops:** dashboards for service health; inhibition avoids alert storms; configs are reloadable.

## Task 2 - Configuration Management & Scalable Production Deployment

* **Tooling:** Ansible with inventories, roles, and vaulted group vars.
* **Security & hardening:** SSH key-only, root login disabled, UFW default-deny, fail2ban, time sync, auditd, SSH ciphers/MACs pinned.
* **Deployments:** rolling serial waves with health checks; Docker runtime installed/pinned; systemd-managed app service.
* **Idempotency:** declarative modules; handlers trigger only on change; --check and lint in CI.

## Task 3 - Incident Management & Reliability Governance

* **IR plan:** roles (IC/Comms/Owner), comms flow (Slack + status page), severity ladder, paging rules, and stakeholder updates schedule.
* **Runbook (example):** DB outage / API latency—detect → triage → mitigate (traffic shed/circuit breaker) → recover → verify.
* **Postmortem:** timeline, root cause, contributing factors, impact, corrective actions with owners/dates; learning items captured.

## Task 4 - Disaster Recovery & Backup Automation

* **Backups:** backup.sh (tar → compress → optional AES-GCM encrypt → checksum → manifest), scheduled with retention.
* **Verification:** verifybackup.py (SHA-256 + archive readability).
* **Restore:** restore.sh (latest or specific point), supports encrypted artifacts.
* **RPO/RTO:** 15–60 min RPO depending on data class; <30 min app restore / <2 h full host.
* **Storage:** S3 (versioning + lifecycle) or NFS; secrets outside VCS; optional cross-region copy.

## Task 5 - Container Security & Compliance Automation

* **CI gates:** image build → vulnerability scan → policy enforcement → sign/attest → deploy if clean.
* **Blocks:** critical/high CVEs or policy violations fail the pipeline; reports surfaced in CI UI and Slack.
* **Supply chain:** immutable tags/digests; optional signature verification at deploy time.

---

## How to validate locally (quick)

* **Task 1:** docker compose up -d in task1-monitoring/; open Prometheus (9090) and Grafana (3000). Trigger InstanceDown by stopping node-exporter to see alerts.
* **Task 2:** ansible-playbook -i inventory/prod.ini site.yml --check then apply; verify systemctl status <app>.
* **Task 4:** run scripts/backup.sh, then verifybackup.py and restore.sh to /tmp/restore.

---

### Final note

Each task includes a README that explains setup, assumptions, and the reasoning behind thresholds, policies, and safeguards, aligning with the assignment’s emphasis on clarity, maintainability, and real-world reliability. 
