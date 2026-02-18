## -----------------------------------------------------------------------------
## Global configuration
## -----------------------------------------------------------------------------
export GCP_PAGER :=
SHELL := /bin/bash

GCP_PROJECT := gke-cluster-458701
LOCATION := us-central1
CLUSTER_NAME := gke-cluster-demo
NAMESPACE := hello-world-ns
INGRESS_NAME := hello-world-ingress

BUCKET_NAME := terraform-state-bucket-2727
TF_DIR := terraform

REPO_NAME := hello-world-repo
REPO_LOCATION := us
IMAGE_NAME := hello-world
IMAGE_TAG := 1.2.5

.PHONY: \
	help check-gcp install-tools \
	tf-bootstrap tf-format tf-init tf-validate tf-plan tf-apply tf-destroy tf-output tf-state \
	tf-bucket create-bucket enable-versioning set-lifecycle add-labels delete-artifact-repo nuke-tf-bucket \
	k8s-validate k8s-validate-server k8s-apply-ns k8s-apply k8s-delete k8s-status k8s-logs \
	k8s-events k8s-create-image-pull-secret k8s-fix-image-pull-secret \
	k8s-ingress-ip k8s-curl k8s-curl-https k8s-smoke k8s-smoke-https k8s-shell k8s-describe k8s-restart \
	k8s-kustomize-validate k8s-kustomize-apply k8s-kustomize-diff k8s-kustomize-delete \
	bg-deploy bg-status bg-switch-blue bg-switch-green bg-rollback bg-cleanup bg-test-blue bg-test-green bg-logs-blue bg-logs-green \
	update-kubeconfig image-verify-arch k8s-cdn-status

.DEFAULT_GOAL := help

help:
	@echo "📚 GKE Cluster Demo - Available Commands"
	@echo ""
	@echo "🔧 Terraform Commands:"
	@echo "  make tf-bootstrap        - Initialize and validate Terraform"
	@echo "  make tf-bucket           - Create GCS bucket for state"
	@echo "  make tf-init             - Initialize Terraform"
	@echo "  make tf-validate         - Validate Terraform configuration"
	@echo "  make tf-plan             - Preview infrastructure changes"
	@echo "  make tf-apply            - Apply infrastructure changes"
	@echo "  make tf-destroy          - Destroy all infrastructure"
	@echo "  make tf-output           - Display Terraform outputs"
	@echo "  make tf-state            - List Terraform state"
	@echo ""
	@echo "☸️  Kubernetes Manifest Commands:"
	@echo "  make k8s-validate        - Validate manifests (client-side)"
	@echo "  make k8s-validate-server - Validate against cluster (server-side)"
	@echo "  make k8s-apply           - Deploy all manifests"
	@echo "  make k8s-status          - Check deployment status"
	@echo "  make k8s-logs            - View application logs"
	@echo "  make k8s-events          - Show recent namespace events"
	@echo "  make k8s-create-image-pull-secret - Create/update Artifact Registry pull secret"
	@echo "  make k8s-fix-image-pull-secret    - Refresh pull secret and restart deployment"
	@echo "  make k8s-ingress-ip      - Print ingress external IP"
	@echo "  make k8s-curl            - Curl ingress endpoint"
	@echo "  make k8s-curl-https      - Curl ingress endpoint over HTTPS"
	@echo "  make k8s-smoke           - Run pods/ingress/http smoke test"
	@echo "  make k8s-smoke-https     - Run pods/ingress/https smoke test"
	@echo "  make k8s-shell           - Open shell in running container"
	@echo "  make k8s-describe        - Describe deployment"
	@echo "  make k8s-restart         - Restart deployment"
	@echo "  make k8s-delete          - Delete all manifests"
	@echo ""
	@echo "🔵🟢 Blue/Green Deployment Commands:"
	@echo "  make bg-deploy           - Deploy blue/green infrastructure"
	@echo "  make bg-status           - Check blue/green deployment status"
	@echo "  make bg-switch-blue      - Switch traffic to blue"
	@echo "  make bg-switch-green     - Switch traffic to green"
	@echo "  make bg-rollback         - Rollback to previous version"
	@echo "  make bg-test-blue        - Port-forward to blue deployment"
	@echo "  make bg-test-green       - Port-forward to green deployment"
	@echo "  make bg-logs-blue        - View blue deployment logs"
	@echo "  make bg-logs-green       - View green deployment logs"
	@echo "  make bg-cleanup          - Delete blue/green resources"
	@echo ""
	@echo "📦 Kustomize Commands:"
	@echo "  make k8s-kustomize-validate - Validate kustomize configuration"
	@echo "  make k8s-kustomize-apply    - Deploy with kustomize"
	@echo "  make k8s-kustomize-diff     - Preview changes"
	@echo "  make k8s-kustomize-delete   - Delete resources"
	@echo ""
	@echo "🛠️  Utility Commands:"
	@echo "  make install-tools       - Install required tools"
	@echo "  make check-gcp           - Verify GCP credentials"
	@echo "  make update-kubeconfig   - Update kubectl configuration"
	@echo "  make image-verify-arch   - Verify image has amd64+arm64 manifests"
	@echo "  make k8s-cdn-status      - Show Cloud CDN status for ingress backend"
	@echo "  make help                - Show this help message"
	@echo ""

check-gcp:
	@echo "🔍 Checking GCP project: $(GCP_PROJECT)"
	@if ! gcloud projects describe $(GCP_PROJECT) --format="value(projectId)" | grep -q $(GCP_PROJECT) >/dev/null 2>&1; then \
		echo "⚠️ Project $(GCP_PROJECT) not found."; \
		exit 1; \
	else \
		echo "✅ GCP project $(GCP_PROJECT) exists."; \
	fi

install-tools:
	@echo "🚀 Running install-tools script..."
	@/bin/bash ./scripts/install-tools.sh

tf-bootstrap: tf-bucket tf-format tf-init tf-validate tf-plan
	@echo "🔄 Running terraform bootstrap..."
	@echo "✅ Terraform bootstrap completed successfully."
	@echo "To apply changes, run 'make tf-apply'."

tf-format:
	terraform -chdir=$(TF_DIR) fmt -recursive
	@echo "✅ Terraform files formatted."

tf-init:
	terraform -chdir=$(TF_DIR) init
	@echo "✅ Terraform initialized."

tf-validate:
	terraform -chdir=$(TF_DIR) validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	terraform -chdir=$(TF_DIR) plan
	@echo "✅ Terraform plan completed."

tf-apply: tf-format tf-validate
	terraform -chdir=$(TF_DIR) apply
	@echo "✅ Terraform resources deployed."

tf-destroy: k8s-delete
	terraform -chdir=$(TF_DIR) destroy
	@echo "✅ Terraform resources destroyed."

tf-output:
	terraform -chdir=$(TF_DIR) output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	terraform -chdir=$(TF_DIR) state list
	@echo "✅ Terraform state listed."
	@echo "🔍 To view specific resource, run 'terraform state show <resource_name>'."

tf-bucket: create-bucket enable-versioning set-lifecycle add-labels
	@echo "✅ GCS bucket created and configured for Terraform state."

create-bucket:
	@echo "🚀 Creating GCS bucket: gs://$(BUCKET_NAME)"
	gcloud storage buckets create gs://$(BUCKET_NAME) \
		--location=$(LOCATION) \
		--default-storage-class=STANDARD \
		--uniform-bucket-level-access \
		--public-access-prevention \
		--retention-period=60s

enable-versioning:
	@echo "🔄 Enabling versioning..."
	gcloud storage buckets update gs://$(BUCKET_NAME) --versioning

set-lifecycle:
	@echo "🧹 Setting lifecycle rule to delete objects older than 365 days"
	echo '{"rule":[{"action":{"type":"Delete"},"condition":{"age":365}}]}' > lifecycle.json
	gcloud storage buckets update gs://$(BUCKET_NAME) --lifecycle-file=lifecycle.json
	rm -f lifecycle.json

add-labels:
	@echo "🏷️  Adding labels..."
	gcloud storage buckets update gs://$(BUCKET_NAME) \
		--update-labels=environment=terraform,purpose=state-storage

delete-artifact-repo:
	@echo "⚠️  WARNING: This will permanently delete the Artifact Registry repository: $(REPO_NAME)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🗑️  Deleting repository $(REPO_NAME) from $(REPO_LOCATION) in project $(GCP_PROJECT)..."; \
		gcloud artifacts repositories delete $(REPO_NAME) \
			--location=$(REPO_LOCATION) \
			--project=$(GCP_PROJECT) --quiet; \
	else \
		echo "❌ Deletion cancelled."; \
	fi

nuke-tf-bucket:
	@echo "⚠️  WARNING: This will permanently delete the bucket: $(BUCKET_NAME)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🔄 Deleting bucket contents and bucket..."; \
		gcloud storage rm --recursive gs://$(BUCKET_NAME)/** || true; \
		gcloud storage buckets delete gs://$(BUCKET_NAME) --quiet || true; \
		echo "✅ Bucket deleted."; \
	else \
		echo "❎ Aborted."; \
	fi

# Kubernetes Manifest Deployment Targets
k8s-validate:
	@echo "🔍 Validating Kubernetes manifests (kustomize/client-side)..."
	kubectl apply --dry-run=client -k manifests/
	@echo "✅ All manifests are valid."

k8s-validate-server:
	@echo "🔍 Validating manifests against cluster (kustomize/server-side)..."
	kubectl apply --dry-run=server -k manifests/
	@echo "✅ All manifests are valid against cluster."

k8s-apply-ns:
	@echo "🚀 Creating namespace..."
	kubectl apply -f manifests/hello-world-ns.yaml
	@echo "✅ Namespace created."

k8s-apply:
	@echo "🚀 Deploying Kubernetes manifests with kustomize..."
	kubectl apply -k manifests/
	@echo "✅ Kubernetes resources deployed."

k8s-delete:
	@echo "⚠️  WARNING: This will delete all Kubernetes resources."
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🗑️  Deleting Kubernetes resources..."; \
		kubectl delete -k manifests/ --ignore-not-found=true; \
		echo "✅ Kubernetes resources deleted."; \
	else \
		echo "❎ Aborted."; \
	fi

k8s-status:
	@echo "📊 Deployment Status"
	@echo "===================="
	@echo ""
	@echo "--- Namespaces ---"
	kubectl get namespaces $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "--- Deployments ---"
	kubectl get deployments -n $(NAMESPACE) 2>/dev/null || echo "No deployments found"
	@echo ""
	@echo "--- Pods ---"
	kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "--- Services ---"
	kubectl get services -n $(NAMESPACE) 2>/dev/null || echo "No services found"
	@echo ""
	@echo "--- LoadBalancer URL ---"
	@kubectl get service hello-world-service -n $(NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null && echo "" || echo "LoadBalancer not ready yet"

k8s-logs:
	@echo "📜 Fetching logs from hello-world deployment..."
	kubectl logs -n $(NAMESPACE) -l app=hello-world --tail=100

k8s-events:
	@echo "📅 Fetching recent events from $(NAMESPACE)..."
	kubectl get events -n $(NAMESPACE) --sort-by=.lastTimestamp

k8s-create-image-pull-secret:
	@echo "🔐 Creating/updating Artifact Registry pull secret in $(NAMESPACE)..."
	@kubectl create secret docker-registry artifact-registry-credentials -n $(NAMESPACE) \
		--docker-server=us-central1-docker.pkg.dev \
		--docker-username=oauth2accesstoken \
		--docker-password="$$(gcloud auth print-access-token)" \
		--docker-email=unused@example.com \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "✅ Image pull secret ready: artifact-registry-credentials"

k8s-fix-image-pull-secret: k8s-create-image-pull-secret
	@echo "🔄 Restarting deployment to apply updated image pull secret..."
	kubectl rollout restart deployment/hello-world -n $(NAMESPACE)
	kubectl rollout status deployment/hello-world -n $(NAMESPACE) --timeout=180s
	@echo "⚠️  Warning events from the last 5 minutes:"
	@RECENT_WARNINGS=$$(kubectl get events -n $(NAMESPACE) --field-selector type=Warning --sort-by=.lastTimestamp --no-headers 2>/dev/null | awk '($$1 ~ /^[0-9]+s$$/ || $$1 ~ /^[1-4]m$$/)'); \
	if [ -n "$$RECENT_WARNINGS" ]; then \
		echo "LAST SEEN   TYPE      REASON                            OBJECT                             MESSAGE"; \
		echo "$$RECENT_WARNINGS"; \
	else \
		echo "✅ No warning events in the last 5 minutes."; \
	fi
	@echo "✅ Pull secret refreshed and deployment restarted."

k8s-ingress-ip:
	@echo "🌐 Ingress external IP:"
	@kubectl get ingress $(INGRESS_NAME) -n $(NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo ""

k8s-curl:
	@IP=$$(kubectl get ingress $(INGRESS_NAME) -n $(NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	if [ -z "$$IP" ]; then \
		echo "❌ Ingress IP not ready yet"; \
		exit 1; \
	fi; \
	echo "🌐 Curling http://$$IP/ (with retries)..."; \
	for i in 1 2 3 4 5 6; do \
		CODE=$$(curl -sS -o /dev/null -w "%{http_code}" --max-time 10 "http://$$IP/" || true); \
		if [ "$$CODE" = "200" ]; then \
			curl -i --max-time 10 "http://$$IP/"; \
			exit 0; \
		fi; \
		echo "⏳ Attempt $$i/6 returned '$$CODE', retrying..."; \
		sleep 5; \
	done; \
	echo "❌ HTTP endpoint not ready after retries"; \
	exit 1

k8s-curl-https:
	@IP=$$(kubectl get ingress $(INGRESS_NAME) -n $(NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	if [ -z "$$IP" ]; then \
		echo "❌ Ingress IP not ready yet"; \
		exit 1; \
	fi; \
	echo "🌐 Curling https://$$IP/"; \
	curl -k -i --max-time 15 "https://$$IP/"

k8s-smoke:
	@echo "🧪 Running Kubernetes smoke test..."
	@kubectl rollout status deployment/hello-world -n $(NAMESPACE) --timeout=180s >/dev/null || { \
		echo "❌ Deployment rollout not complete"; \
		exit 1; \
	}
	@PODS=$$(kubectl get pods -n $(NAMESPACE) --request-timeout=20s --no-headers 2>/tmp/k8s-smoke.err); \
	if [ $$? -ne 0 ]; then \
		echo "❌ Unable to query pods (API connectivity issue)"; \
		cat /tmp/k8s-smoke.err; \
		exit 1; \
	fi; \
	echo "$$PODS" | awk '{print $$2}' | grep -vqE '^([0-9]+/[0-9]+)$$' && { echo "❌ Unexpected pod readiness output"; exit 1; } || true; \
	echo "$$PODS" | awk '{split($$2,a,"/"); if (a[1] != a[2]) exit 1} END {if (NR==0) exit 1}' || { echo "❌ Not all pods are ready"; exit 1; }
	@IP=$$(kubectl get ingress $(INGRESS_NAME) -n $(NAMESPACE) --request-timeout=20s -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/tmp/k8s-smoke.err); \
	if [ $$? -ne 0 ]; then \
		echo "❌ Unable to query ingress (API connectivity issue)"; \
		cat /tmp/k8s-smoke.err; \
		exit 1; \
	fi; \
	if [ -z "$$IP" ]; then \
		echo "❌ Ingress IP not ready yet"; \
		exit 1; \
	fi; \
	echo "🌐 Testing http://$$IP/"; \
	CODE=""; \
	for i in 1 2 3 4 5 6; do \
		CODE=$$(curl -sS -o /dev/null -w "%{http_code}" --max-time 10 "http://$$IP/" || true); \
		[ "$$CODE" = "200" ] && break; \
		echo "⏳ HTTP not ready yet (attempt $$i/6, code '$$CODE')"; \
		sleep 5; \
	done; \
	if [ "$$CODE" != "200" ]; then \
		echo "❌ Smoke test failed: HTTP $$CODE"; \
		exit 1; \
	fi; \
	echo "✅ Smoke test passed (pods ready, ingress IP assigned, HTTP 200)"

k8s-smoke-https:
	@echo "🧪 Running Kubernetes HTTPS smoke test..."
	@kubectl rollout status deployment/hello-world -n $(NAMESPACE) --timeout=180s >/dev/null || { \
		echo "❌ Deployment rollout not complete"; \
		exit 1; \
	}
	@PODS=$$(kubectl get pods -n $(NAMESPACE) --request-timeout=20s --no-headers 2>/tmp/k8s-smoke.err); \
	if [ $$? -ne 0 ]; then \
		echo "❌ Unable to query pods (API connectivity issue)"; \
		cat /tmp/k8s-smoke.err; \
		exit 1; \
	fi; \
	echo "$$PODS" | awk '{print $$2}' | grep -vqE '^([0-9]+/[0-9]+)$$' && { echo "❌ Unexpected pod readiness output"; exit 1; } || true; \
	echo "$$PODS" | awk '{split($$2,a,"/"); if (a[1] != a[2]) exit 1} END {if (NR==0) exit 1}' || { echo "❌ Not all pods are ready"; exit 1; }
	@IP=$$(kubectl get ingress $(INGRESS_NAME) -n $(NAMESPACE) --request-timeout=20s -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/tmp/k8s-smoke.err); \
	if [ $$? -ne 0 ]; then \
		echo "❌ Unable to query ingress (API connectivity issue)"; \
		cat /tmp/k8s-smoke.err; \
		exit 1; \
	fi; \
	if [ -z "$$IP" ]; then \
		echo "❌ Ingress IP not ready yet"; \
		exit 1; \
	fi; \
	echo "🌐 Testing https://$$IP/"; \
	CODE=$$(curl -k -sS -o /dev/null -w "%{http_code}" --max-time 15 "https://$$IP/"); \
	if [ "$$CODE" != "200" ]; then \
		echo "❌ HTTPS smoke test failed: HTTP $$CODE"; \
		exit 1; \
	fi; \
	echo "✅ HTTPS smoke test passed (pods ready, ingress IP assigned, HTTPS 200)"

k8s-shell:
	@echo "🐚 Opening shell in hello-world container..."
	@POD=$$(kubectl get pod -n $(NAMESPACE) -l app=hello-world -o jsonpath='{.items[0].metadata.name}'); \
	kubectl exec -it -n $(NAMESPACE) $$POD -- /bin/sh

k8s-describe:
	@echo "📝 Describing hello-world deployment..."
	kubectl describe deployment hello-world -n $(NAMESPACE)

k8s-restart:
	@echo "🔄 Restarting hello-world deployment..."
	kubectl rollout restart deployment/hello-world -n $(NAMESPACE)
	kubectl rollout status deployment/hello-world -n $(NAMESPACE)
	@echo "✅ Deployment restarted."

# Kustomize Commands
k8s-kustomize-validate:
	@echo "🔍 Validating kustomize configuration..."
	kubectl kustomize manifests/ | kubectl apply --dry-run=client -f -
	@echo "✅ Kustomize configuration is valid."

k8s-kustomize-apply:
	@echo "🚀 Deploying with kustomize..."
	kubectl apply -k manifests/
	@echo "✅ Resources deployed with kustomize."

k8s-kustomize-diff:
	@echo "📊 Previewing kustomize changes..."
	kubectl kustomize manifests/ | kubectl diff -f - || true

k8s-kustomize-delete:
	@echo "⚠️  Deleting kustomize resources..."
	kubectl delete -k manifests/ --ignore-not-found=true
	@echo "✅ Kustomize resources deleted."

# Blue/Green Deployment Commands
bg-deploy:
	@echo "🔵🟢 Deploying Blue/Green infrastructure..."
	kubectl apply -k manifests/blue-green/
	@echo "✅ Blue/Green deployments created."
	@echo "📊 Use 'make bg-status' to check the status"

bg-status:
	@echo "🔵🟢 Blue/Green Deployment Status"
	@./scripts/blue-green-switch.sh status

bg-switch-blue:
	@echo "🔵 Switching traffic to BLUE deployment..."
	@./scripts/blue-green-switch.sh blue

bg-switch-green:
	@echo "🟢 Switching traffic to GREEN deployment..."
	@./scripts/blue-green-switch.sh green

bg-rollback:
	@echo "⏮️  Rolling back to previous deployment..."
	@./scripts/blue-green-switch.sh rollback

bg-cleanup:
	@echo "🗑️  Deleting Blue/Green deployment resources..."
	kubectl delete -k manifests/blue-green/ --ignore-not-found=true
	@echo "✅ Blue/Green resources deleted."

bg-test-blue:
	@echo "🔵 Testing Blue deployment..."
	@POD=$$(kubectl get pod -n $(NAMESPACE) -l version=blue -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No blue pods found"; \
		exit 1; \
	fi; \
	echo "Port-forwarding to blue deployment on localhost:8080..."; \
	kubectl port-forward -n $(NAMESPACE) $$POD 8080:8080

bg-test-green:
	@echo "🟢 Testing Green deployment..."
	@POD=$$(kubectl get pod -n $(NAMESPACE) -l version=green -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No green pods found"; \
		exit 1; \
	fi; \
	echo "Port-forwarding to green deployment on localhost:8081..."; \
	kubectl port-forward -n $(NAMESPACE) $$POD 8081:8080

bg-logs-blue:
	@echo "📜 Fetching logs from BLUE deployment..."
	kubectl logs -n $(NAMESPACE) -l version=blue --tail=100 -f

bg-logs-green:
	@echo "📜 Fetching logs from GREEN deployment..."
	kubectl logs -n $(NAMESPACE) -l version=green --tail=100 -f

# Utility Commands
update-kubeconfig:
	@echo "🔧 Updating kubeconfig for GKE cluster..."
	gcloud container clusters get-credentials $(CLUSTER_NAME) --region=$(LOCATION) --project=$(GCP_PROJECT)
	@echo "✅ Kubeconfig updated."

image-verify-arch:
	@echo "🔎 Verifying multi-arch image support..."
	@IMAGE_REF="us-central1-docker.pkg.dev/$(GCP_PROJECT)/$(REPO_NAME)/$(IMAGE_NAME):$(IMAGE_TAG)"; \
	if ! command -v docker >/dev/null 2>&1; then \
		echo "❌ docker is required for this check"; \
		exit 1; \
	fi; \
	if ! docker buildx imagetools inspect "$$IMAGE_REF" >/tmp/image-verify-arch.out 2>/tmp/image-verify-arch.err; then \
		echo "❌ Unable to inspect $$IMAGE_REF"; \
		cat /tmp/image-verify-arch.err; \
		exit 1; \
	fi; \
	cat /tmp/image-verify-arch.out | grep -q "linux/amd64" || { echo "❌ linux/amd64 not found"; exit 1; }; \
	cat /tmp/image-verify-arch.out | grep -q "linux/arm64" || { echo "❌ linux/arm64 not found"; exit 1; }; \
	echo "✅ Multi-arch image verified: $$IMAGE_REF"

k8s-cdn-status:
	@echo "📡 Checking Cloud CDN status on ingress backend..."
	@BACKEND=$$(kubectl -n $(NAMESPACE) describe ingress $(INGRESS_NAME) 2>/tmp/k8s-cdn-status.err | sed -n 's/.*"\(k8s[0-9]-[^"]*hello-world-service-80[^"]*\)":"[A-Z]*".*/\1/p' | head -n1); \
	if [ -z "$$BACKEND" ]; then \
		BACKEND=$$(gcloud compute backend-services list --global --project $(GCP_PROJECT) --filter='name~hello-world-ns-hello-world-service-80' --format='value(name)' | head -n1); \
	fi; \
	if [ -z "$$BACKEND" ]; then \
		echo "❌ Could not resolve ingress backend service name (ingress may still be provisioning)"; \
		cat /tmp/k8s-cdn-status.err 2>/dev/null || true; \
		exit 1; \
	fi; \
	echo "Backend: $$BACKEND"; \
	gcloud compute backend-services describe "$$BACKEND" --global --project $(GCP_PROJECT) \
		--format='yaml(name,enableCDN,cdnPolicy.cacheMode,timeoutSec,connectionDraining.drainingTimeoutSec,logConfig.enable)'