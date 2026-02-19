# Ensure the KMS key exists for Artifact Registry
resource "google_kms_key_ring" "repo_key_ring" {
  depends_on = [google_project_service.api_services]

  name     = "artifact-registry-key-ring"
  location = var.region

  lifecycle {
    prevent_destroy = false
  }
}

# Ensure the KMS key exists for Artifact Registry
# trunk-ignore(checkov/CKV_GCP_82)
resource "google_kms_crypto_key" "repo_key" {
  name            = "artifact-registry-key"
  key_ring        = google_kms_key_ring.repo_key_ring.id
  rotation_period = "86400s"
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = false
  }
}
