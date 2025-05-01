provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "compute-api" {
  service                    = "compute.googleapis.com"
  disable_on_destroy         = true
  disable_dependent_services = true
}

resource "google_project_service" "container-api" {
  service                    = "container.googleapis.com"
  disable_on_destroy         = true
  disable_dependent_services = true
}

/*
resource "google_project_service" "cloud-run-api" {
  service                    = "run.googleapis.com"
  disable_on_destroy         = true
  disable_dependent_services = true
}

// Optional: Service account (conditionally created)
resource "google_service_account" "default" {
  count        = var.create_service_account ? 1 : 0
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "Service account for GKE"
  depends_on   = [google_project_service.cloud-run-api]
}
*/

resource "google_container_cluster" "gke-cluster" {
  depends_on = [
    google_project_service.container-api,
    google_project_service.compute-api
  ]
  name                     = "gke-cluster"
  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  ip_allocation_policy {}
}

resource "google_container_node_pool" "gke_preemptible_nodes" {
  depends_on = [google_container_cluster.gke-cluster]
  name       = "gke-node-pool"
  cluster    = google_container_cluster.gke-cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
    //service_account = google_service_account.default[0].email
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

/*
resource "google_container_cluster" "autopilot" {
  depends_on          = [google_project_service.kubernetes-api]
  name                = "autopilot"
  enable_autopilot    = true
  deletion_protection = false
}
*/