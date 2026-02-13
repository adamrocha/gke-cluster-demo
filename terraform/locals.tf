resource "terraform_data" "update_kubeconfig" {
  depends_on = [google_container_cluster.gke_cluster]

  triggers_replace = {
    cluster_name = google_container_cluster.gke_cluster.name
    endpoint     = google_container_cluster.gke_cluster.endpoint
    master_auth  = sha1(jsonencode(google_container_cluster.gke_cluster.master_auth))
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔑 Updating kubeconfig for cluster ${google_container_cluster.gke_cluster.name}..."
      
      # Use gcloud to get credentials and update kubeconfig
      gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} \
        --region=${var.region} \
        --project=${var.project_id} \
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Ensure the Artifact Registry repository exists
resource "google_artifact_registry_repository" "repo" {
  depends_on = [
    google_kms_crypto_key_iam_member.artifact_registry_kms
  ]
  description   = "Docker repository for GKE images"
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.repo_key.id

  lifecycle {
    prevent_destroy = false
  }
}

# Lookup the image safely - commented out as it causes issues when image doesn't exist yet
# The docker build process below will create the image
# data "google_artifact_registry_docker_image" "my_image" {
#   location      = google_artifact_registry_repository.repo.location
#   repository_id = google_artifact_registry_repository.repo.repository_id
#   image_name    = "${var.image_name}:${var.image_tag}"
# }

# Multi-architecture build using docker buildx
resource "terraform_data" "docker_buildx" {
  depends_on = [google_artifact_registry_repository.repo]

  triggers_replace = {
    image_tag  = var.image_tag
    platforms  = join(",", var.platforms)
    dockerfile = filemd5("../app/Dockerfile")
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔨 Building multi-architecture image..."
      
      # Login to GAR
      gcloud auth configure-docker "${var.region}-docker.pkg.dev" --quiet
      
      # Create buildx builder if not exists
      docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
      
      # Build and push multi-arch image
      docker buildx build \
        --platform ${join(",", var.platforms)} \
        --tag "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/${var.image_name}:${var.image_tag}" \
        --push \
        ../app/
      
      echo "✅ Multi-arch image pushed successfully"
    EOT
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

# # Build image only if it doesn't exist
# resource "null_resource" "image_build" {
#   depends_on = [
#     google_artifact_registry_repository.repo,
#     data.external.image_exists
#   ]
#   triggers = {
#     image_tag = var.image_tag
#   }
#   provisioner "local-exec" {
#     environment = {
#       PROJECT_ID = var.project_id
#       REGION     = var.region
#       REPO_NAME  = var.repo_name
#       IMAGE_NAME = var.image_name
#       IMAGE_TAG  = var.image_tag
#       PLATFORMS  = join(",", var.platforms)
#     }
#     command     = <<EOT
#       if [ "${data.external.image_exists.result.exists}" = "false" ]; then
#         ../scripts/docker-image.sh
#       else
#         echo "Image already exists, skipping build."
#       fi
#     EOT
#     interpreter = ["bash", "-c"]
#   }
# }

# # Get the image digest from Artifact Registry
# data "external" "image_digest" {
#   depends_on = [null_resource.image_build]
#   program = [
#     "bash", "-c", <<EOT
#       set -euo pipefail

#       PROJECT_ID="${var.project_id}"
#       REGION="${var.region}"
#       REPO_NAME="${var.repo_name}"
#       IMAGE_NAME="${var.image_name}"
#       IMAGE_TAG="${var.image_tag}"

#       DIGEST=$(gcloud artifacts docker images list \
#         "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME" \
#         --include-tags \
#         --filter="tags=$IMAGE_TAG" \
#         --format="get(DIGEST)")

#       echo "{\"digest\": \"$DIGEST\"}"
#     EOT
#   ]
# }


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