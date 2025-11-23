# **Task 1: Monitoring, Observability & Alerting System**

This task creates a full monitoring setup using **Prometheus**, **Grafana**, and **Alertmanager**. It follows the main steps outlined in the assignment:  
**collection, visualization, alerting**.

The system gathers metrics from instrumented services, stores and evaluates them in Prometheus, shows insights in Grafana, and produces actionable alerts using Alertmanager.

## **1. Architecture Overview**

Here is the architecture diagram showing the entire flow:

✔ Instrumented services that expose metrics  
✔ Prometheus scraping (pull model)  
✔ Grafana for dashboards (visualization)  
✔ Alertmanager for notifications (alerting)  

## **2. Components**

### **Instrumented Services (Collection Layer)**

These are application or system parts that expose metrics at a `/metrics` endpoint. Examples include:

* Application services (Node.js, Go, Python, Java with Prometheus libraries)  
* Node Exporter (system metrics)  
* cAdvisor (container metrics)  

Prometheus uses the **pull model** to scrape these metrics.

### **Prometheus (Scraping, Storage, Evaluation)**

Prometheus carries out three main tasks:

1. **Scraping**
   * It pulls metrics from instrumented services at set intervals.

2. **Storage (TSDB)**
   * It saves all collected metrics in its Time Series Database (TSDB).

3. **Evaluation**
   * It checks alert rules and recording rules defined in the configurations.

Your Prometheus configuration file is available at:

```
configs/prometheus.yml
```

Alert rules are specified in:

```
configs/alertrules.yml
```

### **Grafana (Visualization Layer)**

Grafana connects to Prometheus as a data source and offers:

* Dashboards for CPU, memory, latency, and error rates  
* Visualization of time-series metrics  
* Shared operational insights for teams  

Datasource provisioning file:

```
configs/grafanadatasource.yml
```

### **Alertmanager (Alert Routing & Notification Layer)**

Prometheus sends alert events to Alertmanager, which directs them to:

* Slack  
* Email  
* PagerDuty  
* Webhooks  

Alertmanager manages:

* Deduplication  
* Grouping  
* Silencing  
* Notification delivery  

## **3. Monitoring Flow (Required from PDF)**

### **Collection, Visualization, Alerting**

1. **Collection**  
   Prometheus gathers metrics from instrumented services.

2. **Visualization**  
   Grafana queries Prometheus to create dashboards.

3. **Alerting**  
   Prometheus activates rules → Alertmanager → Notification channels.

## **4. Key Metrics to Monitor**

The system usually monitors:

* CPU usage  
* Memory availability  
* Disk usage  
* Request rate  
* Error rate (4xx, 5xx)  
* Latency percentiles  
* Container metrics (CPU/memory limits, restarts)  

## **5. Alerting Strategy**

Common alert categories include:

* High CPU or memory usage  
* Node or service downtime  
* Increased error rates  
* High request latency  
* Low available disk space  

Severity levels:

* **Warning** → investigation needed  
* **Critical** → immediate action needed  
* **Page** → on-call escalation  

Alert rules are defined in:

```
configs/alertrules.yml
```

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

## **7. Summary**

This task builds a complete observability stack that provides:

* **Metrics collection** from instrumented services  
* **Time-series data processing** with Prometheus  
* **Actionable dashboards** with Grafana  
* **Reliable alerting** with Alertmanager  