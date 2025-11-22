# Runbook – Production Incident Quick Actions

**Goal:** Move fast, reduce user impact, and restore SLOs. Use this playbook with the Incident Response Plan (IRP).

---

## 0) First 5 Minutes (All Incidents)

1. **Acknowledge** the alert (≤ 5 min).
2. **Declare** incident & set **SEV** (IC assigned) – open Slack `#incident-<YYYYMMDD-HHMM>` + Jira `INC-xxxx`.
3. **Snapshot context:** Grafana screenshots, last deploy SHA, change/feature flags.
4. **Stabilize first** (rollback/traffic-shift/circuit-breakers), then diagnose.

---

## 1) Quick Checks (links & commands)

- **Prometheus targets:** `http://<prom>:9090/targets`
- **Active alerts:** `http://<prom>:9090/alerts`
- **Alertmanager UI:** `http://<am>:9093`
- **Grafana dashboards:** `http://<grafana>:3000` → Explore

**Prometheus reload (no restart):**
```bash
curl -X POST http://<prom>:9090/-/reload
````

**Recent deploys (example):**

```bash
git --no-pager log --oneline -n 10
```

---

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

---

## 3) Common Scenarios & Actions

### A) **API down / 5xx > 5% (SEV-1)**

**Symptoms:** `HTTPErrorRateHigh`, user errors, status 5xx spikes.

**Immediate actions (choose safest first):**

* **Rollback** to previous stable version.
* **Feature-flag off** recent risky toggles.
* **Circuit-break** slow/failed downstreams; **graceful degrade** (read-only / cached responses).

**Then diagnose:**

* Which routes error?

  ```
  sum by (path) (rate(http_requests_total{job="app",code=~"5.."}[5m]))
  ```
* Downstream latency/errors if instrumented.

**Recover:** Errors back to baseline ≥ 30 min; remove mitigations gradually.

---

### B) **Latency spike P95 > 500ms (SEV-2)**

**Symptoms:** `HTTPLatencyP95Above`, user slowness.

**Mitigations:**

* **Rollback** latest deploy; disable heavy features.
* **Autoscale** app; ensure DB/queue headroom.
* **Rate-limit** hot endpoints; **increase CDN TTL** for static/content paths.

**Deep dive:** P95 by route; DB/query histograms; container CPU throttling.

---

### C) **InstanceDown / node unreachable (SEV-2)**

**Symptoms:** `InstanceDown` firing; one or more targets down.

**Mitigations:**

* **Drain traffic** from bad node; replace instance/pod.
* Check **ingress/SDN/SG** rules; restart agent/exporters.

**Probe:**

```
up{instance="<host:port>"} == 0
```

---

### D) **DiskFillingSoon (< 4h) (SEV-2/3)**

**Mitigations:**

* **Purge** logs/caches; expand volume; lower retention.
* If DB, move cold data or enable compression.

**Verify:** Disk headroom > 24h.

---

### E) **TLS cert expiring (SEV-3)**

**Symptoms:** `SSLCertExpiringSoon` from Blackbox.

**Mitigations:**

* Renew cert (ACME/LE or CA); redeploy ingress/reverse proxy.

**Probe:**

```
(probe_ssl_last_chain_expiry_timestamp_seconds - time()) < 14*24*3600
```

---

## 4) Rollback / Traffic Controls (patterns)

* **App rollback:** use your deploy tool (`kubectl rollout undo`, `helm rollback`, CI “Revert” pipeline).
* **Traffic shift:** lower canary to 0%; switch route to last stable; disable new paths at gateway.
* **Circuit breaker:** reduce concurrency/timeouts to a flaky backend; serve cached responses where possible.

**Always record:** exact SHA/flag/replica changes.

---

## 5) Communication Cadence

* **SEV-1:** status page + internal update every **15 min**.
* **SEV-2:** every **30 min**.
* Include: current impact, actions taken, ETA/next update, owner names.

Templates are in **incident-response-plan.md**.

---

## 6) Close & Learn

* **Close** when SLOs stable for ≥ 60 min and mitigations are safely unwound.
* Open **postmortem** within 24h; publish ≤ 5 business days.
* Create **CPAs** with owners & due dates; add evidence links.

---

## 7) Links

* IRP: `incident-response-plan.md`
* Postmortem Template: `postmortem-template.md`
* Dashboards: *<insert URLs>*
* On-call & escalation: *<insert contacts>*



