output "vpc_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.gke_vpc.name
}

output "subnet_name" {
  description = "The name of the subnet."
  value       = google_compute_subnetwork.gke_subnet.name
}

output "subnet_cidr" {
  description = "The CIDR range of the subnet."
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster."
  value       = google_container_cluster.gke_cluster.endpoint
}

output "load_balancer_ip" {
  description = "External IP of the hello-world service"
  value       = kubernetes_service.hello_world_service.status[0].load_balancer[0].ingress[0].ip
}

output "local_ip" {
  description = "Local IP address of the machine running Terraform"
  value       = local.my_ip
}
