output "vpc_name" {
  value = google_compute_network.gke_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.gke_subnet.name
}

output "subnet_cidr" {
  value = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.gke_cluster.endpoint
  description = "hello-world endpoint"
}

output "load_balancer_ip" {
  value       = kubernetes_service.hello_world_service.status[0].load_balancer[0].ingress[0].ip
  description = "External IP of the hello-world service"
}

output "local_ip" {
  value       = local.my_ip
  description = "Local IP address of the machine running Terraform"
}
