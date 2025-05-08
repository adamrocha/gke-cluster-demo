variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created."
  default     = "gke-cluster-458701"
}

variable "region" {
  type        = string
  description = "The GCP region for the GKE cluster and network resources."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The GCP zone for the GKE node pool."
  default     = "us-central1-a"
}

variable "environment" {
  type        = string
  description = "The environment for the GKE cluster (e.g., dev, staging, prod)."
  default     = "dev"
}