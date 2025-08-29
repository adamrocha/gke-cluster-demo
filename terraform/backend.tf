// bucket: Name of your GCS bucket
// prefix: Optional path (like a folder) for organizing state files

terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket-2727"
    prefix = "terraform/state/dev"
  }
}