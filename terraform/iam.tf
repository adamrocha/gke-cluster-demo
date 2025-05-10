resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/container.clusterViewer",
    "roles/container.clusterAdmin",
    "roles/container.admin",
    "roles/container.developer",
    "roles/container.serviceAgent",
    "roles/container.viewer",
    "roles/container.hostServiceAgentUser"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

// Optional: Service account (conditionally created)
// Using a dedicated SA for GKE nodes is a security best practice.
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "GKE Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "tls_private_key" "gke_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret" "gke_private_key" {
  secret_id = "gke-private-key"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}

resource "google_project_iam_member" "ansible_sa_roles" {
  role = each.key
  for_each = toset([
    "roles/compute.admin",
    "roles/compute.networkAdmin",
    "roles/compute.viewer",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.serviceAccountTokenCreator"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.ansible_service_account.email}"
}

resource "google_service_account" "ansible_service_account" {
  account_id   = "ansible-service-account"
  display_name = "Ansible Service Account"
  description  = "Ansible Service Account"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account_key" "ansible_inventory_key" {
  depends_on = [
    google_project_service.api_services,
    google_service_account.ansible_service_account
  ]

  service_account_id = google_service_account.ansible_service_account.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
  public_key_type    = "TYPE_X509_PEM_FILE"

  provisioner "local-exec" {
    command     = "mkdir -p /opt/keys"
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    command     = "echo '${base64decode(google_service_account_key.ansible_inventory_key.private_key)}' > /opt/keys/ansible-inventory-key.json"
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    command     = "chmod 600 /opt/keys/ansible-inventory-key.json"
    interpreter = ["bash", "-c"]
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret" "ansible_key_secret" {
  secret_id = "ansible_inventory_key"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ansible_key_secret-version" {
  secret      = google_secret_manager_secret.ansible_key_secret.id
  secret_data = base64decode(google_service_account_key.ansible_inventory_key.private_key)

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "gke_private_key_version" {
  secret      = google_secret_manager_secret.gke_private_key.id
  secret_data = tls_private_key.gke_ssh.private_key_pem

  provisioner "local-exec" {
    command     = "echo '${tls_private_key.gke_ssh.private_key_pem}' > /opt/keys/gke-private-key.pem"
    interpreter = ["bash", "-c"]
  }
}