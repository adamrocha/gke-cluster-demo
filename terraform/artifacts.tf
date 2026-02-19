# Ensure the Artifact Registry repository exists
resource "google_artifact_registry_repository" "repo" {
  depends_on = [
    google_kms_crypto_key_iam_member.artifact_registry_kms
  ]
  description   = "Docker repository for GKE images"
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"
  kms_key_name  = var.enable_artifact_registry_cmek ? google_kms_crypto_key.repo_key[0].id : null

  docker_config {
    immutable_tags = var.enable_artifact_registry_immutable_tags
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Multi-architecture build using docker buildx
resource "terraform_data" "docker_buildx" {
  depends_on = [google_artifact_registry_repository.repo]

  triggers_replace = {
    image_tag  = var.image_tag
    platforms  = join(",", var.platforms)
    dockerfile = filemd5("../app/Dockerfile")
    entrypoint = filemd5("../app/entrypoint.sh")
    index_html = filemd5("../app/index.html")
    nginx_conf = filemd5("../app/nginx.conf")
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔨 Building multi-architecture image..."

      IMAGE_PATH="${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/${var.image_name}:${var.image_tag}"

      # Skip build/push if immutable tag already exists
      if gcloud artifacts docker images describe "$${IMAGE_PATH}" --project "${var.project_id}" >/dev/null 2>&1; then
        echo "ℹ️  Image $${IMAGE_PATH} already exists. Skipping build and push."
        exit 0
      fi

      # Login to GAR
      gcloud auth configure-docker "${var.region}-docker.pkg.dev" --quiet

      # Create buildx builder if not exists
      docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder

      # Build and push multi-arch image
      docker buildx build \
        --platform ${join(",", var.platforms)} \
        --tag "$${IMAGE_PATH}" \
        --push \
        ../app/

      echo "✅ Multi-arch image pushed successfully"
    EOT
    interpreter = ["bash", "-c"]
  }
}