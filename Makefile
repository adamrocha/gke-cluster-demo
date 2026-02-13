export GCP_PAGER :=
SHELL := /bin/bash
GCP_PROJECT=gke-cluster-458701
LOCATION=us-central1
BUCKET_NAME=terraform-state-bucket-2727
REPO_NAME=hello-world-repo
REPO_LOCATION=us
TF_DIR=terraform
NAMESPACE=hello-world-ns

.PHONY: check-gcp help

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
	@echo "🔄 Runnin terraform bootstrap..."
	@echo "✅ Terraform bootstrap completed successfully."
	@echo "To apply changes, run 'make tf-apply'."

tf-format:
	terraform -chdir=$(TF_DIR) fmt -check -recursive
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

tf-apply:
	terraform -chdir=$(TF_DIR) apply
	@echo "✅ Terraform resources deployed."

tf-destroy:
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
	@echo "🔍 Validating Kubernetes manifests..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=client -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=client -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=client -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid."

k8s-validate-server:
	@echo "🔍 Validating manifests against cluster (server-side)..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=server -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=server -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=server -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid against cluster."

k8s-apply-ns:
	@echo "🚀 Creating namespace..."
	kubectl apply -f manifests/hello-world-ns.yaml
	@echo "✅ Namespace created."

k8s-apply: k8s-apply-ns
	@echo "🚀 Deploying Kubernetes manifests..."
	kubectl apply -f manifests/hello-world-deployment.yaml
	kubectl apply -f manifests/hello-world-service.yaml
	@echo "✅ Kubernetes resources deployed."

k8s-delete:
	@echo "⚠️  WARNING: This will delete all Kubernetes resources."
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🗑️  Deleting Kubernetes resources..."; \
		kubectl delete -f manifests/hello-world-service.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-deployment.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-ns.yaml --ignore-not-found=true; \
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
	@echo "📜 
	
	
	
	
	ing logs from hello-world deployment..."
	kubectl logs -n $(NAMESPACE) -l app=hello-world --tail=100

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
	gcloud container clusters get-credentials $(GCP_PROJECT) --region=$(LOCATION) --project=$(GCP_PROJECT)
	@echo "✅ Kubeconfig updated."