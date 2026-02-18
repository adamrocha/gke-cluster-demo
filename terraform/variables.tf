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

variable "cluster_name" {
  description = "The name of the GKE cluster."
  default     = "gke-cluster-demo"
  type        = string
}

# variable "terraform_state_bucket" {
#   description = "The name of the GCS bucket for storing Terraform state."
#   default     = "terraform-state-bucket-1337"
#   type        = string
# }

variable "enable_arm_nodes" {
  description = "Enable ARM-based node machine type when true."
  default     = false
  type        = bool
}

variable "machine_type" {
  description = "The machine type for the GKE nodes."
  # default     = "e2-micro"
  # default     = "e2-small"
  default = "e2-medium"
  type    = string
}

variable "arm_machine_type" {
  description = "The ARM-based machine type for the GKE nodes."
  default     = "t2a-standard-2"
  type        = string
}

variable "arm_node_locations" {
  description = "Zones to use for ARM node pools when enable_arm_nodes is true."
  default     = ["us-central1-a", "us-central1-b", "us-central1-f"]
  type        = list(string)
}

variable "image_type" {
  description = "The image type for the GKE nodes."
  # ARM and x86 nodes both support COS_CONTAINERD on GKE.
  default = "COS_CONTAINERD"
  type    = string
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
  default     = "1.2.5"
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

variable "platforms" {
  description = "Platforms for Docker buildx"
  default     = ["linux/amd64", "linux/arm64"]
  type        = list(string)
}
