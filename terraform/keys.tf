/*
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

resource "google_secret_manager_secret_version" "gke_private_key_version" {
  secret      = google_secret_manager_secret.gke_private_key.id
  secret_data = tls_private_key.gke_ssh.private_key_pem

  provisioner "local-exec" {
    command     = "mkdir -p /opt/keys"
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    command     = "echo '${tls_private_key.gke_ssh.private_key_pem}' > /opt/keys/gke-private-key.pem"
    interpreter = ["bash", "-c"]
  }
}
*/


/*
resource "google_secret_manager_secret_version" "ansible_key_secret-version" {
  secret      = google_secret_manager_secret.ansible_key_secret.id
  secret_data = base64decode(google_service_account_key.ansible_inventory_key.private_key)

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
  depends_on = [
    google_project_service.api_services,
    google_service_account.ansible_service_account
  ]
  secret_id = "ansible-inventory-key"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}
*/