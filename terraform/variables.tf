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

variable "kubeconfig_path" {
  type        = string
  description = "The path to the kubeconfig file for accessing the GKE cluster."
  default     = "~/.kube/config"
}

variable "instance_type" {
  type        = string
  description = "The machine type for the GKE nodes."
  default     = "e2-medium"
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "1.2.2"
  type        = string
}

variable "image_digest" {
  description = "Digest of the Docker image to be used in the deployment"
  default     = "sha256:2e62673af8af6d70d0088bfa3aefcd5081be95da63c40ca651928782baa1b4ae"
  type        = string
}

variable "namespace" {
  description = "Name of the Kubernetes namespace"
  default     = "hello-world-ns"
  type        = string
}

variable "service" {
  description = "Name of the Kubernetes service"
  default     = "hello-world-service"
  type        = string
}

variable "deployment" {
  description = "Name of the Kubernetes deployment"
  default     = "hello-world"
  type        = string
}
