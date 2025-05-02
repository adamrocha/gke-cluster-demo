
resource "google_project_service" "compute-api" {
  service                    = "compute.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "container-api" {
  service                    = "container.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}
/*
resource "google_project_service" "cloud-logging-api" {
  service                    = "logging.googleapis.com"
  disable_on_destroy         = true
  disable_dependent_services = true
}
resource "google_project_service" "cloud-monitoring-api" {
  service                    = "monitoring.googleapis.com"
  disable_on_destroy         = true
  disable_dependent_services = true
}
*/

resource "google_container_cluster" "gke-cluster" {
  depends_on = [
    google_project_service.compute-api,
    google_project_service.container-api
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
// Optional: Service account (conditionally created)
resource "google_service_account" "default" {
  depends_on   = []
  count        = var.create_service_account ? 1 : 0
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "Service account for GKE"
}
*/

/*
resource "google_container_cluster" "autopilot" {
  depends_on = [
    google_project_service.container-api,
    google_project_service.compute-api,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnet
  ]
  name                = "autopilot"
  enable_autopilot    = true
  deletion_protection = false
}
*/