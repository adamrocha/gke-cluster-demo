
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

# IAM roles for the service account
locals {
  sa_roles = [
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.networkUser",
    "roles/editor"
  ]
}

resource "google_project_iam_member" "gke-node-pool-roles" {
  for_each = toset(local.sa_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.gke-service-account.email}"
}

// Optional: Service account (conditionally created)
// Using a dedicated SA for GKE nodes is a security best practice.
resource "google_service_account" "gke-service-account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "Service account for GKE"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_container_cluster" "gke-cluster" {
  depends_on = [
    google_project_service.compute-api,
    google_project_service.container-api,
    google_service_account.gke-service-account,
    google_project_iam_member.gke-node-pool-roles
  ]
  name                = "node-pool-cluster"
  network             = google_compute_network.vpc_network.name
  subnetwork          = google_compute_subnetwork.subnet.name
  initial_node_count  = 1
  deletion_protection = false
  //remove_default_node_pool = false
  ip_allocation_policy {}
}

resource "google_container_node_pool" "gke-node-pool" {
  depends_on = [
    google_container_cluster.gke-cluster,
    google_project_service.compute-api,
    google_project_service.container-api,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnet,
    google_service_account.gke-service-account
  ]
  //name               = "gke-node-pool"
  cluster = google_container_cluster.gke-cluster.name
  //initial_node_count = 3

  node_config {
    service_account = google_service_account.gke-service-account.email
    preemptible     = true
    machine_type    = "e2-micro"
    # Using a dedicated service account is recommended over the default compute SA
    # Using a custom service account for GKE nodes is a security best practice
    # The default compute service account has broad permissions
    # and should be avoided for GKE nodes.
    # The service account should have the necessary IAM roles for GKE
    # and any other services the nodes need to access.
    # For example, if the nodes need to access Cloud Storage, you can add:
    # roles/storage.objectViewer
    # roles/storage.objectAdmin
    # roles/storage.admin
    # roles/logging.logWriter
    # roles/monitoring.metricWriter
    # roles/monitoring.viewer
    # roles/monitoring.admin
    # roles/compute.viewer
    # roles/compute.networkViewer
    # roles/compute.securityAdmin
    # roles/compute.instanceAdmin
    # roles/compute.networkAdmin
    # roles/compute.autoscaler
    # roles/compute.networkUser
    # roles/compute.storageAdmin
    # roles/compute.viewer
    # roles/compute.networkAdmin
    # roles/compute.securityAdmin
    # roles/compute.instanceAdmin
    # roles/compute.networkViewer
    # Consider using more restrictive scopes based on workload needs for production
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

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