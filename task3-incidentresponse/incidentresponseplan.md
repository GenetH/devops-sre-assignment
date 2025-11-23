# Incident Response Plan

**Goal:** Fix user impact quickly and safely. Steps: **Detect, Triage, Mitigate, Communicate, Recover, Learn**.

## 1) When to declare & severities
- **SEV-1 (Critical):** Major outage or payments blocked. Page immediately. **Updates every 15 min.**
- **SEV-2 (High):** Key feature degraded (high latency, 5xx). Page on-call. **Updates every 30 min.**
- **SEV-3 (Medium):** Partial impact or workaround exists. Handle during business hours.
- **SEV-4 (Low):** Early warning (disk growth, cert expiring). Track as ticket.

## 2) Roles (one person may hold two; **IC is single owner**)
- **Incident Commander (IC):** Owns severity, priorities, and decisions.
- **Tech Lead (TL):** Leads diagnosis and mitigations, delegates checks.
- **Comms Lead (CL):** Posts internal and status-page updates at the cadence above.
- **Scribe:** Captures timeline, screenshots, logs, deploy SHAs, opens postmortem.

## 3) Where we operate
- **War room:** Slack `#incident-<YYYYMMDD-hhmm>`
- **Ticket:** Jira `INC-<id>`
- **Dashboards:** Grafana (Production Overview, API, DB)
- **Status page:** `https://status.example.com`

## 4) Lifecycle (checklist)
1. **Ack alert (≤5 min).** Assign **IC**.
2. **Declare SEV**, open war room and ticket, assign **TL, CL, Scribe**.
3. **Triage (≤10 min):** scope, start time, last deploy or feature flag, impacted %.
4. **Mitigate fast:** rollback, traffic shift, scale, disable new flag.
5. **Communicate on cadence:** impact, actions, ETA, **next update time**.
6. **Recover:** metrics stable **≥60 min**; validate key flows (login, checkout).
7. **Close & learn:** mark resolved; **postmortem** opened within **24 h**.

## 5) Rules during incidents
- One command chain via **IC**.
- **Change freeze** for SEV-1 unless IC approves.
- Keep **evidence** (graphs, PromQL, logs, commit SHAs).
- **Blameless:** fix systems and process, not people.

## 6) Message templates
**Internal (start):**  
“Declaring **SEV-2**: API latency since 11:20 UTC. Impact: ~25% of users slow checkout. Mitigation: rollback API v1.25 to v1.24, check DB. Next update 11:45 UTC. IC: @name, TL: @name, CL: @name. Ticket: INC-1234.”

**Status page (investigating):**  
“We’re investigating increased API latency affecting some users. Next update at 11:45 UTC.”

**Resolved:**  
“Resolved. 11:20 to 11:42 UTC API slowness due to faulty deploy; rollback at 11:33 UTC. Metrics normal. Postmortem will follow.”

## 7) SLO/Alert pointers (align with Task-1)
- **Error rate (5xx%)**, **P95/P99 latency**, availability, CPU, memory, disk, container health.
- Alerts link back to runbooks and dashboards.