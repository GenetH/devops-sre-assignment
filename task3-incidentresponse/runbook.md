# Runbook, Production Incident Quick Actions

**Goal:** Move quickly, minimize user impact, and restore SLOs. Use this playbook alongside the Incident Response Plan (IRP).

## 0) First 5 Minutes (All Incidents)

1. **Acknowledge** the alert (≤ 5 min).
2. **Declare** the incident and set **SEV** (IC assigned) by opening Slack `#incident-<YYYYMMDD-HHMM>` and Jira `INC-xxxx`.
3. **Snapshot context:** Take screenshots in Grafana, note the last deploy SHA, and check change/feature flags.
4. **Stabilize first** by rolling back, shifting traffic, or using circuit breakers, then diagnose.

## 1) Quick Checks (links & commands)

- **Prometheus targets:** `http://<prom>:9090/targets`
- **Active alerts:** `http://<prom>:9090/alerts`
- **Alertmanager UI:** `http://<am>:9093`
- **Grafana dashboards:** `http://<grafana>:3000` → Explore

**Prometheus reload (no restart):**
```bash
curl -X POST http://<prom>:9090/-/reload
```

**Recent deploys (example):**
```bash
git --no-pager log --oneline -n 10
```
## 2) High-Signal PromQL Cheatsheet

**App 5xx rate (%):**
```
100 * sum(rate(http_requests_total{job="app",code=~"5.."}[5m]))
    / sum(rate(http_requests_total{job="app"}[5m]))
```

**App P95 latency (s):**
```
histogram_quantile(0.95,
  sum by (le) (rate(http_request_duration_seconds_bucket{job="app"}[5m]))
)
```

**P95 by route (find hot endpoints):**
```
histogram_quantile(0.95,
  sum by (le, path) (rate(http_request_duration_seconds_bucket{job="app"}[5m]))
)
```

**Host CPU %:**
```
100 * (1 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])))
```

**Host Memory %:**
```
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

**Disk filling in < 4h:**
```
predict_linear(node_filesystem_free_bytes{fstype!~"tmpfs|overlay|squashfs"}[6h], 4*3600) < 0
```

**Top 5 containers by CPU (cAdvisor):**
```
topk(5, sum by (name) (rate(container_cpu_usage_seconds_total[5m])))
```

**Website probe success (Blackbox):**
```
avg(probe_success{job="website-https"})
```

## 3) Common Scenarios & Actions

### A) **API down / 5xx > 5% (SEV-1)**

**Symptoms:** `HTTPErrorRateHigh`, user errors, spikes in status 5xx.

**Immediate actions (choose safest first):**

* **Rollback** to the previous stable version.
* **Turn off** recent risky feature flags.
* **Circuit-break** slow or failed downstreams and **gracefully degrade** to read-only or cached responses.

**Then diagnose:**

* Which routes are causing errors?
  ```
  sum by (path) (rate(http_requests_total{job="app",code=~"5.."}[5m]))
  ```
* Check downstream latency and errors, if instrumented.

**Recover:** Wait for errors to return to baseline for at least 30 minutes, then remove mitigations gradually.

### B) **Latency spike P95 > 500ms (SEV-2)**

**Symptoms:** `HTTPLatencyP95Above`, user slowness.

**Mitigations:**

* **Rollback** the latest deploy and disable heavy features.
* **Autoscale** the app and check DB/queue headroom.
* **Rate-limit** busy endpoints and **increase CDN TTL** for static/content paths.

**Deep dive:** Look at P95 by route, check DB/query histograms, and monitor container CPU throttling.

### C) **InstanceDown / node unreachable (SEV-2)**

**Symptoms:** `InstanceDown` alert triggered; one or more targets are down.

**Mitigations:**

* **Drain traffic** from the problematic node and replace the instance or pod.
* Check **ingress/SDN/SG** rules and restart agents/exporters.

**Probe:**
```
up{instance="<host:port>"} == 0
```

### D) **DiskFillingSoon (< 4h) (SEV-2/3)**

**Mitigations:**

* **Purge** logs and caches, expand the volume, or lower retention.
* If using a database, move cold data or enable compression.

**Verify:** Ensure disk headroom is greater than 24 hours.

### E) **TLS cert expiring (SEV-3)**

**Symptoms:** `SSLCertExpiringSoon` alert from Blackbox.

**Mitigations:**

* Renew the certificate (using ACME/LE or CA) and redeploy the ingress or reverse proxy.

**Probe:**
```
(probe_ssl_last_chain_expiry_timestamp_seconds - time()) < 14*24*3600
```
## 4) Rollback / Traffic Controls (patterns)

* **App rollback:** Use your deploy tool (`kubectl rollout undo`, `helm rollback`, CI “Revert” pipeline).
* **Traffic shift:** Lower canary to 0%, switch route to the last stable, and disable new paths at the gateway.
* **Circuit breaker:** Reduce concurrency or timeouts for a flaky backend and serve cached responses when possible.

**Always record:** The exact SHA, flag, and replica changes.

## 5) Communication Cadence

* **SEV-1:** Provide a status page and internal updates every **15 minutes**.
* **SEV-2:** Provide updates every **30 minutes**.
* Include current impact, actions taken, ETA for the next update, and names of owners.

Templates are available in **incident-response-plan.md**.

## 6) Close & Learn

* **Close** the incident when SLOs are stable for at least 60 minutes and mitigations are safely removed.
* Open a **postmortem** within 24 hours and publish it within 5 business days.
* Create **CPAs** with owners and due dates, adding links to evidence.

## 7) Links

* IRP: `incident-response-plan.md`
* Postmortem Template: `postmortem-template.md`
* Dashboards: *<insert URLs>*
* On-call & escalation: *<insert contacts>*