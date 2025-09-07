GCP_PROJECT=gke-cluster-458701
LOCATION=us-central1
BUCKET_NAME=terraform-state-bucket-2727
REPO_NAME=hello-world-repo
REPO_LOCATION=us
TF_DIR=terraform

.PHONY: check-gcp

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
	cd $(TF_DIR) && terraform fmt
	@echo "✅ Terraform files formatted."

tf-init:
	cd $(TF_DIR) && terraform init
	@echo "✅ Terraform initialized."

tf-validate:
	cd $(TF_DIR) && terraform validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	cd $(TF_DIR) && terraform plan
	@echo "✅ Terraform plan completed."

tf-apply:
	cd $(TF_DIR) && terraform apply
	@echo "✅ Terraform resources deployed."

tf-destroy:
	cd $(TF_DIR) && terraform destroy
	@echo "✅ Terraform resources destroyed."

tf-output:
	cd $(TF_DIR) && terraform output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	cd $(TF_DIR) && terraform state list
	@echo "✅ Terraform state listed."
	@echo "🔍 To view specific resource, run 'terraform state show <resource_name>'."

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

nuke:
	@echo "⚠️  This will delete the bucket: $(BUCKET_NAME)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🔄 Deleting contents..."; \
		gsutil -m rm -r gs://$(BUCKET_NAME) || true; \
	else \
		echo "❎ Aborted."; \
	fi