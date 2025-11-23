# Postmortem, <Short descriptive title>
**Date (UTC):** …  **SEV:** …  **IC:** …  **TL:** …  **CL:** …  **Ticket:** INC-…  
**Services:** …  **Customer Impact (plain language):** …

## 1) Executive summary
We had a failure, affecting several users for a specific duration. Here’s the current status.

## 2) Impact
- Start → End (UTC), duration
- Percentage of requests/users affected; SLO/SLA impact
- Business symptoms, like checkout failures

## 3) Timeline (UTC)
| Time | Event | Source |
|---|---|---|
| 11:20 | Alert fired (API P95) | Alertmanager |
| 11:23 | SEV-2 declared, war room opened | Slack |
| 11:33 | Rolled back API v1.25 to v1.24 | Deploy logs |
| 11:42 | Metrics normal; status updated | Grafana |

## 4) Root cause
- Trigger:
- Contributing factors:
- How detected:
- Why we didn’t prevent it sooner:

## 5) What went well
- Quick rollback, clear leadership, good dashboards

## 6) What can improve
- Noisy alerts, missing step in runbook, communication gaps

## 7) Corrective & Preventive Actions (CPAs)
| ID | Action | Owner | Priority | Due | Evidence/Link |
|---|---|---|---|---|---|
| A1 | Add pre-deploy canary and latency guard | … | P1 | … | PR/Runbook |
| A2 | Adjust alert thresholds by route | … | P1 | … | Prom rules |
| A3 | Improve status-page templates | … | P2 | … | docs |

## 8) Artifacts / Links
Dashboards, PromQL queries, logs, PRs/SHAs, Jira tickets, status-page entries.

> Blameless: we improve systems and processes, not individuals.