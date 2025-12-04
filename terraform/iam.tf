resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",      # ADD THIS
    "storage-api.googleapis.com" 
    //"secretmanager.googleapis.com",
    //"networkmanagement.googleapis.com"
    //"logging.googleapis.com",
    //"oslogin.googleapis.com",
    //"geminicloudassist.googleapis.com"
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
    "roles/artifactory.wriiter",
    "Roles/artifactory.reader",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

/*
resource "google_service_account" "ansible_service_account" {
  account_id   = "ansible-service-account"
  display_name = "Ansible Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "ansible_sa_roles" {
  role = each.key
  for_each = toset([
    "roles/compute.admin",
    "roles/compute.networkAdmin",
    "roles/compute.viewer"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.ansible_service_account.email}"
}
*/

/*
resource "google_service_account" "gcs_service_account" {
  account_id   = "gcs-service-account"
  display_name = "GCS Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  depends_on = [google_project_service.api_services]
  role       = each.key
  for_each = toset([
    //"roles/storage.admin",
    //"roles/storage.objectAdmin",
    //"roles/storage.objectCreator",
    //"roles/storage.objectViewer"
  ])
  bucket = var.terraform_state_bucket
  member = "serviceAccount:${google_service_account.gcs_service_account.email}"

  lifecycle {
    prevent_destroy = false
  }
}
*/