variable "project_id" {
  type    = string
  default = "gke-cluster-458610"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "create_service_account" {
  type    = bool
  default = false
}