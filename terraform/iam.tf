resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage-api.googleapis.com",
    "cloudkms.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/container.defaultNodeServiceAccount",
    "roles/artifactregistry.admin",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Grant Artifact Registry service account permission to use the KMS key
resource "google_kms_crypto_key_iam_member" "artifact_registry_kms" {
  crypto_key_id = google_kms_crypto_key.repo_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_id}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}