output "vpc_name" {
  value = google_compute_network.gke_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.gke_subnet.name
}

output "subnet_cidr" {
  value = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.terraform_state.name}"
  description = "The URL of the GCS bucket."
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.gke_cluster.endpoint
  description = "hello-world endpoint"
}

output "load_balancer_ip" {
  value       = kubernetes_service.hello_world_service.status[0].load_balancer[0].ingress[0].ip
  description = "External IP of the hello-world service"
}
