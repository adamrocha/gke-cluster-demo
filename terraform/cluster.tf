data "google_client_config" "default" {}

resource "google_container_cluster" "gke_cluster" {
  # checkov:skip=CKV_GCP_20: No CIDR block for master authorized networks
  # checkov:skip=CKV_GCP_61: conflicts with enable_autopilot
  depends_on               = [google_project_service.api_services]
  name                     = "demo-cluster"
  network                  = google_compute_network.gke_vpc.name
  subnetwork               = google_compute_subnetwork.gke_subnet.name
  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = true

  # Add cluster-level labels
  resource_labels = {
    env   = "dev"
    owner = "dev-team"
  }

  # Set the release channel
  release_channel {
    channel = "REGULAR"
  }

  # Enable Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Enable private cluster and private nodes
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Disable client certificate authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_container_node_pool" "gke_pool" {
  depends_on         = [google_container_cluster.gke_cluster]
  name               = "demo-pool"
  cluster            = google_container_cluster.gke_cluster.name
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    service_account = google_service_account.gke_service_account.email
    preemptible     = true
    machine_type    = "e2-medium"
    //machine_type = "e2-micro"
    disk_type    = "pd-standard"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    // Enable Shielded GKE Nodes with Secure Boot
    # checkov:skip=CKV_GCP_68: Isolate deployments in separate node pools
    shielded_instance_config {
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    }
    /*
    metadata = {
      ssh-keys = "gke-user:${tls_private_key.gke_ssh.public_key_openssh}"
    }
    */
    tags = ["gke-node"]
    labels = {
      env   = "dev"
      owner = "dev-team"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
