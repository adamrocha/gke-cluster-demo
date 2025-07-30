BUCKET_NAME=terraform-state-bucket-2727
LOCATION=us-central1
TF_DIR=terraform

.PHONY: all create-bucket enable-versioning set-lifecycle clean

tf-tasks: tf-format tf-init tf-validate tf-plan
	@echo "🚀 Running Terraform tasks..."
	@echo "✅ Terraform tasks completed successfully."
	@echo "To apply changes, run 'make tf-apply'."

tf-bucket: create-bucket enable-versioning set-lifecycle add-labels
	@echo "✅ GCS bucket created and configured for Terraform state."


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

clean:
	@echo "⚠️  This will delete the bucket: $(BUCKET_NAME)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🔄 Deleting contents..."; \
		gsutil -m rm -r gs://$(BUCKET_NAME) || true; \
	else \
		echo "❎ Aborted."; \
	fi