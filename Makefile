# Makefile for local k3d GitOps and Observability platform

CLUSTER_NAME ?= k3d-gitops-cluster
K3D_CONFIG   ?= bootstrap/k3d-config.yaml

.PHONY: help up down bootstrap-argocd bootstrap-crds init status

help: ## Display available commands
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Provision the local k3d cluster
	@echo "==> Creating k3d cluster from config..."
	k3d cluster create --config $(K3D_CONFIG) || true
	@echo "==> Cluster is ready. Context switched automatically."

bootstrap-crds: ## Pre-install Prometheus Operator CRDs via Server-Side Apply
	@echo "==> Pre-installing Prometheus Operator CRDs..."
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml

bootstrap-argocd: ## Install ArgoCD into the cluster
	@echo "==> Creating argocd namespace..."
	kubectl create namespace argocd || true
	@echo "==> Installing latest stable ArgoCD manifests via server-side apply..."
	kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "==> Waiting for ArgoCD server components to be healthy..."
	kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=600s
	@echo "==> ArgoCD installation completed successfully."

init: up bootstrap-crds bootstrap-argocd ## Bootstrap the entire local infrastructure
	@echo "==> Applying Root GitOps Application..."
	kubectl apply -f bootstrap/root-app.yaml
	@echo "==> Cluster and GitOps engine initialized."

down: ## Tear down and delete the local k3d cluster
	@echo "==> Deleting k3d cluster..."
	k3d cluster delete $(CLUSTER_NAME)

status: ## Inspect cluster node and pod health
	@echo "==> Nodes:"
	kubectl get nodes -o wide
	@echo "\n==> Core Pods:"
	kubectl get pods -A
