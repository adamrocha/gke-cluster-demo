// This file contains the configuration for the VPC network and subnetwork
// for the GKE cluster. It also includes firewall rules to allow internal
// traffic and SSH access for testing purposes.

resource "google_compute_network" "gke_vpc" {
  depends_on              = [google_project_service.api_services]
  name                    = "gke-vpc"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
  description             = "VPC for GKE"
}

resource "google_compute_subnetwork" "gke_subnet" {
  depends_on = [
    google_project_service.api_services,
    google_compute_network.gke_vpc
  ]
  name                     = "gke-subnet"
  ip_cidr_range            = "10.0.0.0/16"
  network                  = google_compute_network.gke_vpc.id
  description              = "GKE Subnet"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"       # Options: INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN
    flow_sampling        = 0.5                    # Sampling rate between 0.0 and 1.0
    metadata             = "INCLUDE_ALL_METADATA" # Options: INCLUDE_ALL_METADATA, EXCLUDE_ALL_METADATA, CUSTOM_METADATA
  }
}

// Firewall rule to allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  depends_on = [google_compute_network.gke_vpc]
  name       = "allow-internal"
  network    = google_compute_network.gke_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
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
  source_ranges = [
    "10.0.0.0/16",
    "0.0.0.0/0"
  ]
  direction = "INGRESS"
  priority  = 65534
}

// Firewall rule to allow SSH from anywhere (only for testing!)
resource "google_compute_firewall" "allow_ssh" {
  depends_on = [google_compute_network.gke_vpc]
  network    = google_compute_network.gke_vpc.name
  name       = "allow-ssh"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 1000
}


resource "google_compute_firewall" "allow_tls" {
  depends_on = [google_compute_network.gke_vpc]
  network    = google_compute_network.gke_vpc.name
  name       = "allow-tls"
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  direction     = "EGRESS"
  priority      = 1000
}
