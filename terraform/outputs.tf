output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  value = google_compute_subnetwork.subnet.ip_cidr_range
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.terraform_state.name}"
  description = "The URL of the GCS bucket."
}
