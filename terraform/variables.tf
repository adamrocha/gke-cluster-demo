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

variable "terraform_state_bucket" {
  type        = string
  description = "The name of the GCS bucket for storing Terraform state."
  default     = "terraform-state-bucket-1337"
}

variable "kubernetes_image" {
  type        = string
  description = "The Docker image for the Kubernetes deployment."
  default     = "gcr.io/gke-cluster-458701/hello-world:1.0.0@sha256:a25f725fdbe5223aed5a3cb6476aa6ac76297efdd45d953762dc6acd8b465f05"
}

variable "kubeconfig_path" {
  type        = string
  description = "The path to the kubeconfig file for accessing the GKE cluster."
  default     = "~/.kube/config"
}

variable "instance_type" {
  type        = string
  description = "The machine type for the GKE nodes."
  default     = "e2-micro"
}