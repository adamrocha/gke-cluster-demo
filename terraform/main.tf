resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
    "networkmanagement.googleapis.com",
    "logging.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false
}


/*
resource "google_container_cluster" "gke_cluster" {
  depends_on = [
    google_project_service.api_services,
    google_service_account.gke_service_account,
    google_project_iam_member.gke_sa_roles
  ]
  name                     = "gke_cluster"
  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  ip_allocation_policy {}

  node_config {
    service_account = google_service_account.gke_service_account.email
    preemptible     = true
    labels = {
      env = "dev"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "gke_pool" {
  depends_on = [
    google_project_service.api_services,
    google_service_account.gke_service_account
  ]
  name               = "gke_pool"
  cluster            = google_container_cluster.gke_cluster.name
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    service_account = google_service_account.gke_service_account.email
    preemptible     = true
    //machine_type    = "e2-micro"
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    metadata = {
      ssh-keys = "gke-user:${tls_private_key.gke_ssh.public_key_openssh}"
    }
    tags = ["gke-node"]
    labels = {
      env = "dev"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
*/

/*
resource "google_container_cluster" "autopilot" {
  depends_on = [
    google_project_service.api_services,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnet
  ]
  name                = "autopilot"
  enable_autopilot    = true
  deletion_protection = false
}
*/