# Ensure the KMS key exists for Artifact Registry
resource "google_kms_key_ring" "repo_key_ring" {
  count      = var.enable_artifact_registry_cmek ? 1 : 0
  depends_on = [google_project_service.api_services]

  name     = "artifact-registry-key-ring"
  location = var.region

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "repo_key" {
  # checkov:skip=CKV_GCP_82: Short rotation period is intentional for this demo environment
  count           = var.enable_artifact_registry_cmek ? 1 : 0
  name            = "artifact-registry-key"
  key_ring        = google_kms_key_ring.repo_key_ring[0].id
  rotation_period = "86400s"
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = false
  }
}
