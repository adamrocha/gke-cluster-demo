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

  log_config {
    aggregation_interval = "INTERVAL_1_MIN"       # Options: INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN
    flow_sampling        = 1.0                    # Sampling rate between 0.0 and 1.0
    metadata             = "EXCLUDE_ALL_METADATA" # Options: INCLUDE_ALL_METADATA, EXCLUDE_ALL_METADATA, CUSTOM_METADATA
  }
}

resource "google_compute_global_address" "gke_lb_ip" {
  name         = "gke-lb-ip"
  description  = "Global IP for GKE Load Balancer"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_firewall" "allow_internal_icmp" {
  name        = "allow-internal-icmp"
  description = "Allow ICMP for diagnostics within GKE VPC"
  network     = google_compute_network.gke_vpc.name

  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  priority      = 65434
}

resource "google_compute_firewall" "allow_internal_dns" {
  name        = "allow-internal-dns"
  description = "Allow DNS (port 53) within GKE VPC"
  network     = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }
  allow {
    protocol = "udp"
    ports    = ["53"]
  }
  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  priority      = 65433
}

resource "google_compute_firewall" "allow_internal_kubelet" {
  name        = "allow-internal-kubelet"
  description = "Allow Kubelet API and kube-proxy metrics within GKE VPC"
  network     = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250", "10256"]
  }
  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  priority      = 65432
}

resource "google_compute_firewall" "allow_internal_vxlan" {
  name        = "allow-internal-vxlan"
  description = "Allow VXLAN overlay network traffic within GKE VPC"
  network     = google_compute_network.gke_vpc.name

  allow {
    protocol = "udp"
    ports    = ["4789"]
  }
  source_ranges = ["10.0.0.0/16"]
  direction     = "INGRESS"
  priority      = 65431
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
