// This file contains the configuration for the VPC network and subnetwork
// for the GKE cluster. It also includes firewall rules to allow internal
// traffic and SSH access for testing purposes.

resource "google_compute_network" "vpc_network" {
  depends_on              = [google_project_service.gke-services]
  name                    = "gke-vpc"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
  description             = "VPC for GKE"
}

resource "google_compute_subnetwork" "subnet" {
  depends_on = [
    google_project_service.gke-services,
    google_compute_network.vpc_network
  ]
  name          = "gke-subnet"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.vpc_network.name
  description   = "Subnet for GKE"
}

// Firewall rule to allow internal traffic
resource "google_compute_firewall" "allow-internal" {
  depends_on = [google_compute_network.vpc_network]
  name       = "allow-internal"
  network    = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.2.0.0/16"]
  direction     = "INGRESS"
  priority      = 65534
}

// Firewall rule to allow SSH from anywhere (only for testing!)
resource "google_compute_firewall" "allow-ssh" {
  depends_on = [google_compute_network.vpc_network]
  network    = google_compute_network.vpc_network.name
  name       = "allow-ssh"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 1000
}