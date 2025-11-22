# Postmortem – <Short descriptive title>
**Date (UTC):** …  **SEV:** …  **IC:** …  **TL:** …  **CL:** …  **Ticket:** INC-…  
**Services:** …  **Customer Impact (plain language):** …

## 1) Executive summary (2–3 sentences)
What broke, who was affected, for how long, and current status.

## 2) Impact
- Start → End (UTC), duration
- % of requests/users affected; SLO/SLA impact
- Business symptoms (e.g., checkout failures)

## 3) Timeline (UTC)
| Time | Event | Source |
|---|---|---|
| 11:20 | Alert fired (API P95) | Alertmanager |
| 11:23 | SEV-2 declared, war room opened | Slack |
| 11:33 | Rolled back API v1.25 → v1.24 | Deploy logs |
| 11:42 | Metrics normal; status updated | Grafana |

## 4) Root cause (5-Whys)
- Trigger:
- Contributing factors:
- How detected:
- Why not prevented sooner:

## 5) What went well
- e.g., quick rollback, clear leadership, good dashboards

## 6) What can improve
- e.g., noisy alerts, missing runbook step, communication gaps

## 7) Corrective & Preventive Actions (CPAs)
| ID | Action | Owner | Priority | Due | Evidence/Link |
|---|---|---|---|---|---|
| A1 | Add pre-deploy canary/latency guard | … | P1 | … | PR/Runbook |
| A2 | Tune alert thresholds by route | … | P1 | … | Prom rules |
| A3 | Improve status-page templates | … | P2 | … | docs |

## 8) Artifacts / Links
Dashboards, PromQL queries, logs, PRs/SHAs, Jira ticket(s), status-page entries.

> **Blameless:** we improve systems and processes, not individuals.
