# **Task 1  Monitoring, Observability & Alerting System**

This task delivers a complete monitoring architecture using **Prometheus**, **Grafana**, and **Alertmanager**.
It follows the required flow from the assignment:
**collection → visualization → alerting**

The system collects metrics from instrumented services, stores and evaluates them in Prometheus, visualizes insights in Grafana, and generates actionable alerts via Alertmanager.

---

## **1. Architecture Overview**

Below is the architecture diagram demonstrating the full flow:

✔ Instrumented services exposing metrics
✔ Prometheus scraping (pull model)
✔ Grafana for dashboards (visualization)
✔ Alertmanager for notifications (alerting)

📌 **Architecture Diagram (Task 1)**
*(Insert your PNG here in your repository)*

```
A_2D_digital_illustration_flowchart_depicts_a_moni.png
```

---

## **2. Components**

### **Instrumented Services (Collection Layer)**

These are application or system components that expose metrics via a `/metrics` endpoint.
Examples include:

* Application services (Node.js, Go, Python, Java with Prometheus libraries)
* Node Exporter (system metrics)
* cAdvisor (container metrics)

Prometheus uses the **pull model** to scrape metrics from these endpoints.

---

### **Prometheus (Scraping, Storage, Evaluation)**

Prometheus performs three core functions:

1. **Scraping**

   * Pulls metrics from instrumented services at configured intervals.

2. **Storage (TSDB)**

   * Stores all collected metrics in its Time Series Database (TSDB).

3. **Evaluation**

   * Evaluates alert rules and recording rules defined in the configs.

Your Prometheus configuration file is located at:

```
configs/prometheus.yml
```

Alert rules are defined in:

```
configs/alertrules.yml
```

---

### **Grafana (Visualization Layer)**

Grafana connects to Prometheus as a datasource and provides:

* Dashboards for CPU, memory, latency, error rates
* Visualization of time-series metrics
* Shared operational insights for teams

Datasource provisioning file:

```
configs/grafanadatasource.yml
```

---

### **Alertmanager (Alert Routing & Notification Layer)**

Prometheus sends alert events to Alertmanager, which routes them to:

* Slack
* Email
* PagerDuty
* Webhooks

Alertmanager handles:

* Deduplication
* Grouping
* Silencing
* Notification delivery

---

## **3. Monitoring Flow (Required from PDF)**

### **Collection → Visualization → Alerting**

1. **Collection**
   Prometheus pulls metrics from instrumented services.

2. **Visualization**
   Grafana queries Prometheus to create dashboards.

3. **Alerting**
   Prometheus triggers rules → Alertmanager → Notification channels.

---

## **4. Key Metrics to Monitor**

The system typically monitors:

* CPU usage
* Memory availability
* Disk usage
* Request rate
* Error rate (4xx, 5xx)
* Latency percentiles
* Container metrics (CPU/mem limits, restarts)

---

## **5. Alerting Strategy**

Common alert categories include:

* High CPU or memory usage
* Node or service down
* Increased error rates
* High request latency
* Low available disk space

Severity levels:

* **Warning** → investigation
* **Critical** → immediate response
* **Page** → on-call escalation

Alert rules are defined in:

```
configs/alertrules.yml
```

---

## **6. Project Structure (as required)**

```
task1-monitoring/
│
├── architecturediagram.png            ← Your PNG diagram
│
├── configs/
│   ├── prometheus.yml                 ← Prometheus scrape config
│   ├── alertrules.yml                 ← Alert rules
│   └── grafanadatasource.yml          ← Grafana provisioning
│
└── README.md                          ← This documentation
```

---

## **7. Summary**

This task implements a complete observability stack that provides:

* **Metrics collection** from instrumented services
* **Time-series data processing** with Prometheus
* **Actionable dashboards** with Grafana
* **Reliable alerting** with Alertmanager

This setup enables proactive monitoring, fast incident detection, and operational visibility—meeting all requirements defined in the assignment PDF.


