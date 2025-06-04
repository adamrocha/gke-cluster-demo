resource "google_storage_bucket" "terraform_state" {
  name                        = var.terraform_state_bucket // Must be globally unique
  location                    = "us-central1"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  # checkov:skip=CKV_GCP_62: Not production. Will fix later
  # Logging should not point to the same bucket; specify a different bucket for logs
  /*
  logging {
    log_bucket        = google_logging_project_bucket_config.log_analytics_bucket.name
    log_object_prefix = "logs/"
  }
  */
  lifecycle {
    prevent_destroy = false
  }

  retention_policy {
    //retention_period = 365 * 24 * 60 * 60 // 1 year in seconds
    //retention_period = 7 * 24 * 60 * 60 // 7 days in seconds
    retention_period = 60 // 1 minute in seconds
    is_locked        = false
  }

  /*
  Uncomment the above block if you want to set a retention policy
  and lock it. This will prevent deletion of objects for the specified period.
  Be cautious with retention policies as they can lead to data loss if not managed properly.
  You can lock the retention policy by setting is_locked to true.
  This will prevent any changes to the retention policy for the specified period.
  Make sure to understand the implications of locking a retention policy.
  Refer to the GCP documentation for more details on retention policies:
  https://cloud.google.com/storage/docs/bucket-lock
  */
  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  labels = {
    environment = "terraform"
    purpose     = "state-storage"
  }
}

resource "google_storage_bucket_object" "folder" {
  depends_on   = [google_storage_bucket.terraform_state]
  name         = "terraform/state/dev" // Trailing slash simulates a folder
  bucket       = var.terraform_state_bucket
  source       = "terraform.tfstate" // Empty object to simulate folder
  content_type = "application/json"
  metadata = {
    environment = "terraform"
    purpose     = "state-storage"
  }

  lifecycle {
    prevent_destroy = false
  }
}

// bucket: Name of your GCS bucket
// prefix: Optional path (like a folder) for organizing state files

/*
terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket-1337"
    prefix = "terraform/state/dev"
  }
}
*/