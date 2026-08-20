
<h1 align="center">Local GitOps & Observability Platform with k3d</h1>

<p align="center">
  <a href="https://github.com/stachenoisy/k3d_gitops_observability">
    <img src="https://img.shields.io/github/stars/stachenoisy/k3d_gitops_observability" alt="GitHub Repo stars">
  </a>
  <a href="https://github.com/stachenoisy/k3d_gitops_observability/commits/main">
    <img src="https://img.shields.io/github/last-commit/stachenoisy/k3d_gitops_observability" alt="GitHub Last Commit">
  </a>
  <a href="https://github.com/stachenoisy/k3d_gitops_observability/commits/main">
    <img src="https://img.shields.io/github/commit-activity/t/stachenoisy/k3d_gitops_observability" alt="GitHub Total Commit">
  </a>
  <a href="https://opensource.org/license/mit">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  </a>
</p>

A production-grade, declarative local Kubernetes development and observability environment running on **k3d (K3s in Docker)** managed via **ArgoCD (App-of-Apps GitOps)**.

---

## Architecture Overview
```text
                      +-----------------------------------+
                      |            Git Repo               |
                      |  (Single Source of Truth - GitOps)|
                      +-----------------+-----------------+
                                        |
                                        v
+--------------------------------------------------------------------------------+
|  k3d Cluster                                                                   |
|                                                                                |
|  +-------------------+        +--------------------+                           |
|  |   Root App        | -----> | Sub Applications   |                           |
|  |   (App-of-Apps)   |        | (Helm / Manifests) |                           |
|  +-------------------+        +---------+----------+                           |
|                                         |                                      |
|            +----------------------------+----------------------------+         |
|            |                            |                            |         |
|            v                            v                            v         |
|   [ Ingress-NGINX ]          [ Monitoring Stack ]           [ Logging Stack ]  |
|   (Port 80/443 mapping)      - Prometheus Operator          - Grafana Loki     |
|            |                 - Grafana (Dashboards)         - Promtail         |
|            |                                                         |         |
|            +-----------------------+---------------------------------+         |
|                                    |                                           |
|                                    v                                           |
|                           [ Target Microservice ]                              |
|                           - Podinfo (Go Web App)                               |
|                           - Auto-metrics & Logs                                |
+------------------------------------+-------------------------------------------+
|
Exposed Ingress Endpoints
+--------------------------+--------------------------+
|                                                     |
v                                                     v
http://app.localtest.me                               http://grafana.localtest.me
(Podinfo App)                                         (Grafana Dashboards & Loki)
```

## Tech Stack & Components

- **Cluster Orchestration:** `k3d` (Lightweight Kubernetes v1.30+ in Docker)
- **GitOps Engine:** `ArgoCD` (Declarative Continuous Delivery using App-of-Apps pattern)
- **Ingress Controller:** `Ingress-NGINX` (Host port routing via `.localtest.me`)
- **Metrics & Alerting:** `kube-prometheus-stack` (Prometheus Operator & Node Exporters)
- **Visualization:** `Grafana` (Pre-configured Dashboards & Datasources)
- **Log Aggregation:** `Grafana Loki` & `Promtail`
- **Sample Workload:** `Podinfo` (Microservice generating telemetry & HTTP traffic)
- **CI Automation:** `GitHub Actions` (YAML linting and Kubernetes schema validation)

---

## Access Points

| Service | URL / Port | Credentials | Purpose |
|---|---|---|---|
| **ArgoCD UI** | `https://localhost:8080` | `admin` / *(retrieved via CLI)* | Continuous Delivery Dashboard |
| **Podinfo App** | `http://app.localtest.me` | None | Sample Microservice UI & Traffic Gen |
| **Grafana** | `http://grafana.localtest.me` | `admin` / `admin` | Cluster & Application Observability |
| **Prometheus** | Managed internally | - | Metrics scraper |
| **Loki** | `http://logging-stack-loki:3100` | - | Centralized Log Engine |

---

## Getting Started

### Prerequisites
- Docker Engine
- `k3d` CLI
- `kubectl`

### Deployment

1. **Bootstrap the Platform:**
   ```bash
   make init
   ```

Provisions the k3d cluster, installs Prometheus Operator CRDs, deploys ArgoCD, and initializes the root GitOps application.

1. Access ArgoCD Dashboard:
Run port-forward in the background:

```bash
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
```

Retrieve the generated admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

2. Teardown Cluster:

```bash
make down
```

