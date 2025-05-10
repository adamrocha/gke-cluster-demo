resource "google_storage_bucket" "terraform_state" {
  name                        = "terraform-state-bucket-123456" // Must be globally unique
  location                    = "us-central1"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true

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
  name    = "terraform/state/dev" # Trailing slash simulates a folder
  bucket  = google_storage_bucket.terraform_state.name
  source  = "/opt/github/gke-cluster/terraform/terraform.tfstate" # Empty object to simulate folder
}


# bucket: Name of your GCS bucket
# prefix: Optional path (like a folder) for organizing state files
/*
terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket-123456"
    prefix = "terraform/state/dev"
  }
}
*/