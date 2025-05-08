// This file contains local variables used in the Terraform configuration.
// These variables are used to simplify the configuration and avoid repetition.

// IAM roles for the service account
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