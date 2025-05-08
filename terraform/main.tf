resource "google_project_service" "api-services" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_iam_member" "gke-sa-roles" {
  for_each = toset([
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.networkUser",
    "roles/editor"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke-service-account.email}"
}

// Optional: Service account (conditionally created)
// Using a dedicated SA for GKE nodes is a security best practice.
resource "google_service_account" "gke-service-account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "GKE Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "ansible-sa-roles" {
  for_each = toset([
    "roles/container.nodeServiceAccount",
    "roles/iam.serviceAccountViewer",
    "roles/compute.viewer",
    "roles/editor"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ansible-service-account.email}"
}

resource "google_service_account" "ansible-service-account" {
  account_id   = "ansible-service-account"
  display_name = "Ansible Service Account"
  description  = "Ansible Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account_key" "ansible-inventory-key" {
  service_account_id = google_service_account.ansible-service-account.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
  depends_on = [
    google_project_service.api-services,
    google_service_account.ansible-service-account,
    google_project_iam_member.ansible-sa-roles
  ]

  provisioner "local-exec" {
    command = "echo '${google_service_account_key.ansible-inventory-key.private_key}' > /opt/keys/ansible-inventory-key.json"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret" "ansible-key-secret" {
  secret_id = "ansible-inventory-key"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ansible-key-secret-version" {
  secret = google_secret_manager_secret.ansible-key-secret.id
  //secret_data = google_service_account_key.ansible-inventory-key.private_key
  secret_data = file("/opt/keys/ansible-inventory-key.json")
}

resource "google_container_cluster" "gke-cluster" {
  depends_on = [
    google_project_service.api-services,
    google_service_account.gke-service-account,
    google_project_iam_member.gke-sa-roles
  ]
  name                     = "gke-cluster"
  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  ip_allocation_policy {}

  node_config {
    service_account = google_service_account.gke-service-account.email
    preemptible     = true
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "gke-pool" {
  depends_on = [
    google_project_service.api-services,
    google_service_account.gke-service-account
  ]
  name               = "gke-pool"
  cluster            = google_container_cluster.gke-cluster.name
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 6
  }

  node_config {
    service_account = google_service_account.gke-service-account.email
    preemptible     = true
    //machine_type    = "e2-micro"
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = {
      env = "dev"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

/*
resource "google_container_cluster" "autopilot" {
  depends_on = [
    google_project_service.gke-services,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnet
  ]
  name                = "autopilot"
  enable_autopilot    = true
  deletion_protection = false
}
*/