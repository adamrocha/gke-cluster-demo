output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  value = google_compute_subnetwork.subnet.ip_cidr_range
}
