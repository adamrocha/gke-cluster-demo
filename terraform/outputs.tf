output "project_id" {
	description = "GCP project ID"
	value       = var.project_id
}

output "region" {
	description = "Primary GCP region"
	value       = var.region
}

output "cluster_name" {
	description = "GKE cluster name"
	value       = google_container_cluster.gke_cluster_demo.name
}

output "cluster_location" {
	description = "GKE cluster location (regional)"
	value       = google_container_cluster.gke_cluster_demo.location
}

output "cluster_endpoint" {
	description = "GKE control plane endpoint"
	value       = google_container_cluster.gke_cluster_demo.endpoint
}

output "workload_identity_pool" {
	description = "Workload Identity pool"
	value       = google_container_cluster.gke_cluster_demo.workload_identity_config[0].workload_pool
}

output "node_pool_name" {
	description = "GKE node pool name"
	value       = google_container_node_pool.node_pool_demo.name
}

output "node_architecture_mode" {
	description = "Current node architecture mode"
	value       = var.enable_arm_nodes ? "arm64" : "amd64"
}

output "effective_node_machine_type" {
	description = "Machine type currently selected for the node pool"
	value       = var.enable_arm_nodes ? var.arm_machine_type : var.machine_type
}

output "node_locations" {
	description = "Node pool zones used for scheduling"
	value       = google_container_node_pool.node_pool_demo.node_locations
}

output "vpc_name" {
	description = "VPC network name"
	value       = google_compute_network.gke_vpc.name
}

output "subnet_name" {
	description = "Primary subnet name"
	value       = google_compute_subnetwork.gke_subnet.name
}

output "ingress_global_ip" {
	description = "Reserved global external IP for GKE ingress"
	value       = google_compute_global_address.gke_lb_ip.address
}

output "artifact_registry_repository" {
	description = "Artifact Registry repository path"
	value       = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "image_reference" {
	description = "Application image reference"
	value       = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${var.repo_name}/${var.image_name}:${var.image_tag}"
}

output "kubeconfig_update_command" {
	description = "Command to refresh kubeconfig for this cluster"
	value       = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster_demo.name} --region=${var.region} --project=${var.project_id}"
}

output "quick_smoke_test_command" {
	description = "Command to run end-to-end Kubernetes smoke test"
	value       = "make k8s-smoke"
}

output "ingress_ssl_certificate_name" {
	description = "GCE SSL certificate name to use with ingress pre-shared-cert annotation"
	value       = google_compute_ssl_certificate.hello_world_ingress_cert.name
}
