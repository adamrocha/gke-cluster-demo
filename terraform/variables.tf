variable "project_id" {
  description = "The GCP project ID where resources will be created."
  default     = "gke-cluster-458701"
  type        = string
}

variable "region" {
  description = "The GCP region for the GKE cluster and network resources."
  default     = "us-central1"
  type        = string
}

variable "zone" {
  description = "The GCP zone for the GKE node pool."
  default     = "us-central1-a"
  type        = string
}

variable "environment" {
  description = "The environment for the GKE cluster (e.g., dev, staging, prod)."
  default     = "dev"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  default     = "gke-cluster-demo"
  type        = string
}

variable "terraform_state_bucket" {
  description = "The name of the GCS bucket for storing Terraform state."
  default     = "terraform-state-bucket-1337"
  type        = string
}

variable "kubeconfig_path" {
  description = "The path to the kubeconfig file for accessing the GKE cluster."
  default     = "~/.kube/config"
  type        = string
}

variable "instance_type" {
  description = "The machine type for the GKE nodes."
  default     = "e2-medium"
  type        = string
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world-repo"
  type        = string
}

variable "image_name" {
  description = "Docker image name"
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
  default     = ""
  type        = string
}

variable "hello_world_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "hello-world-ns"
  type        = string
}

variable "vault_ns" {
  description = "Name of the Vault namespace"
  default     = "vault-ns"
  type        = string
}

variable "monitoring_ns" {
  description = "Name of the monitoring namespace"
  default     = "monitoring-ns"
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

variable "platforms" {
  description = "Platforms for Docker buildx"
  default     = ["linux/amd64", "linux/arm64"]
  type        = list(string)
}
