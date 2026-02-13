resource "google_compute_network" "gke_vpc" {
  depends_on              = [google_project_service.api_services]
  name                    = "gke-vpc"
  description             = "VPC for GKE"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "gke_subnet" {
  depends_on               = [google_project_service.api_services]
  name                     = "gke-subnet"
  description              = "GKE Subnet"
  network                  = google_compute_network.gke_vpc.id
  ip_cidr_range            = "10.0.0.0/16"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.10.0.0/16"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.20.0.0/16"
  }

  # log_config {
  #   aggregation_interval = "INTERVAL_5_SEC"       # Options: INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN
  #   flow_sampling        = 0.5                    # Sampling rate between 0.0 and 1.0
  #   metadata             = "INCLUDE_ALL_METADATA" # Options: INCLUDE_ALL_METADATA, EXCLUDE_ALL_METADATA, CUSTOM_METADATA
  # }
}

resource "google_compute_global_address" "gke_lb_ip" {
  name         = "gke-lb-ip"
  description  = "Global IP for GKE Load Balancer"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_firewall" "allow_internal" {
  name        = "allow-internal"
  description = "Allow internal traffic within the GKE VPC"
  network     = google_compute_network.gke_vpc.name

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
  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "allow-iap-ssh"
  description = "allow SSH access from Google Cloud IP ranges"
  network     = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  priority      = 1000
}

resource "google_compute_router" "nat_router" {
  name        = "nat-router"
  description = "NAT Router"
  region      = var.region
  network     = google_compute_network.gke_vpc.name
}

resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
