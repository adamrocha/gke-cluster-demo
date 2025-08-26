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

variable "cluster_name" {
  description = "The name of the GKE cluster."
  default     = "demo-cluster"
  type        = string
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
  default     = "hello-world-repo"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "1.2.2"
  type        = string
}

variable "image_digest" {
  description = "Digest of the Docker image to be used in the deployment"
  default     = "sha256:2c839df57adc2df9728fe8aa42a3f3c0f66c785ef2f56bec920bce609390c098"
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
