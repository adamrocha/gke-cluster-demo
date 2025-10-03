resource "null_resource" "update_kubeconfig" {
  depends_on = [google_container_cluster.gke_cluster]

  triggers = {
    cluster_name = google_container_cluster.gke_cluster.name
    endpoint     = google_container_cluster.gke_cluster.endpoint
    master_auth  = sha1(jsonencode(google_container_cluster.gke_cluster.master_auth))
  }

  provisioner "local-exec" {
    command     = <<EOF
    gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} \
    --region=${var.region} \
    --project=${var.project_id}
    EOF
    interpreter = ["bash", "-c"]
  }
}

# resource "null_resource" "image_build" {
#   triggers = {
#     always_run = timestamp()
#   }

#   provisioner "local-exec" {
#     command     = "../scripts/docker-image.sh"
#     interpreter = ["bash", "-c"]
#   }
# }

# data "http" "my_ip" {
#   url = "https://4.ident.me"
# }

# locals {
#   my_ip = "${chomp(data.http.my_ip.response_body)}/32"
# }

// This file contains local variables used in the Terraform configuration.
// These variables are used to simplify the configuration and avoid repetition.

# Ensure the KMS key exists for Artifact Registry
# resource "google_kms_key_ring" "repo_key_ring" {
#   name     = "artifact-registry-key-ring"
#   location = var.region
# }

# resource "google_kms_crypto_key" "repo_key" {
#   name            = "artifact-registry-key"
#   key_ring        = google_kms_key_ring.repo_key_ring.id
#   rotation_period = "100000s"
# }

# Ensure the Artifact Registry repository exists
resource "google_artifact_registry_repository" "repo" {
  description   = "Docker repository for GKE images"
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"

  # kms_key_name = google_kms_crypto_key.repo_key.id

  lifecycle {
    prevent_destroy = false
  }
}

# Check if the image exists in Artifact Registry
data "external" "image_exists" {
  depends_on = [google_artifact_registry_repository.repo]
  program = [
    "bash", "-c", <<EOT
      set -euo pipefail

      PROJECT_ID="${var.project_id}"
      REGION="${var.region}"
      REPO_NAME="${var.repo_name}"
      IMAGE_NAME="${var.image_name}"
      IMAGE_TAG="${var.image_tag}"
      
      DIGEST=$(gcloud artifacts docker images list \
        "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME" \
        --include-tags \
        --filter="tags=$IMAGE_TAG" \
        --format="get(DIGEST)")

      if [[ -n "$DIGEST" ]]; then
        echo '{"exists": "true"}'
      else
        echo '{"exists": "false"}'
      fi
    EOT
  ]
}

# Build image only if it doesn't exist
resource "null_resource" "image_build" {
  depends_on = [
    google_artifact_registry_repository.repo,
    data.external.image_exists
  ]
  provisioner "local-exec" {
    environment = {
      PROJECT_ID = var.project_id
      REGION     = var.region
      REPO_NAME  = var.repo_name
      IMAGE_NAME = var.image_name
      IMAGE_TAG  = var.image_tag
      PLATFORMS  = join(",", var.platforms)
    }
    command     = <<EOT
      if [ "${data.external.image_exists.result.exists}" = "false" ]; then
        ../scripts/docker-image.sh
      else
        echo "Image already exists, skipping build."
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Get the image digest from Artifact Registry
data "external" "image_digest" {
  depends_on = [null_resource.image_build]
  program = [
    "bash", "-c", <<EOT
      set -euo pipefail

      PROJECT_ID="${var.project_id}"
      REGION="${var.region}"
      REPO_NAME="${var.repo_name}"
      IMAGE_NAME="${var.image_name}"
      IMAGE_TAG="${var.image_tag}"
      
      DIGEST=$(gcloud artifacts docker images list \
        "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME" \
        --include-tags \
        --filter="tags=$IMAGE_TAG" \
        --format="get(DIGEST)")

      echo "{\"digest\": \"$DIGEST\"}"
    EOT
  ]
}


// IAM roles for the service account
/*
locals {
  sa_roles = [
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.networkUser",
    "roles/editor"
  ]
}

locals {
  api_services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}
*/