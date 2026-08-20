# Makefile for local k3d GitOps and Observability platform

CLUSTER_NAME ?= k3d-gitops-cluster
K3D_CONFIG   ?= bootstrap/k3d-config.yaml

.PHONY: help up down bootstrap-argocd init status

help: ## Display available commands
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Provision the local k3d cluster
	@echo "==> Creating k3d cluster from config..."
	k3d cluster create --config $(K3D_CONFIG)
	@echo "==> Cluster is ready. Context switched automatically."

bootstrap-argocd: ## Install ArgoCD into the cluster
	@echo "==> Creating argocd namespace..."
	kubectl create namespace argocd || true
	@echo "==> Installing latest stable ArgoCD manifests..."
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "==> Waiting for ArgoCD server components to be healthy..."
	kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
	@echo "==> ArgoCD installation completed successfully."

init: up bootstrap-argocd ## Bootstrap the entire local infrastructure
	@echo "==> Cluster and GitOps engine initialized."

down: ## Tear down and delete the local k3d cluster
	@echo "==> Deleting k3d cluster..."
	k3d cluster delete $(CLUSTER_NAME)

status: ## Inspect cluster node and pod health
	@echo "==> Nodes:"
	kubectl get nodes -o wide
	@echo "\n==> Core Pods:"
	kubectl get pods -A
