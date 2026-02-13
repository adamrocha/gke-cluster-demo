resource "terraform_data" "update_kubeconfig" {
  depends_on = [google_container_cluster.gke_cluster_demo]

  triggers_replace = {
    cluster_name = google_container_cluster.gke_cluster_demo.name
    endpoint     = google_container_cluster.gke_cluster_demo.endpoint
    master_auth  = sha1(jsonencode(google_container_cluster.gke_cluster_demo.master_auth))
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔑 Updating kubeconfig for cluster ${google_container_cluster.gke_cluster_demo.name}..."
      
      # Use gcloud to get credentials and update kubeconfig
      gcloud container clusters get-credentials ${google_container_cluster.gke_cluster_demo.name} \
        --region=${var.region} \
        --project=${var.project_id} \
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Ensure the Artifact Registry repository exists
resource "google_artifact_registry_repository" "repo" {
  depends_on = [
    # google_kms_crypto_key_iam_member.artifact_registry_kms
  ]
  description   = "Docker repository for GKE images"
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"
  # kms_key_name  = google_kms_crypto_key.repo_key.id

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
