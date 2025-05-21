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

data "google_client_config" "default" {}
/*
resource "google_container_cluster" "primary" {
  name = google_container_cluster.gke_cluster.name
}
*/
resource "google_container_cluster" "gke_cluster" {
  # checkov:skip=CKV_GCP_20: No CIDR block for master authorized networks
  # checkov:skip=CKV_GCP_61: conflicts with enable_autopilot
  depends_on          = [google_project_service.api_services]
  name                = "gke-cluster"
  network             = google_compute_network.gke_vpc.name
  subnetwork          = google_compute_subnetwork.gke_subnet.name
  deletion_protection = false
  initial_node_count  = 1
  enable_autopilot    = true
  //remove_default_node_pool = true


  # Add cluster-level labels
  resource_labels = {
    env   = "dev"
    owner = "dev"
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
    master_ipv4_cidr_block  = "172.16.0.0/28" # Restrict to an internal IP range
  }
  /*
  # Enable master authorized networks (restrict to trusted CIDR, e.g., office IP or VPN)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = []
      display_name = "Trusted Network"
    }
  }
  */
  # Enable GKE Metadata Server
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  provisioner "local-exec" {
    command     = "mkdir -p /opt/keys"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "/opt/github/gke-cluster/scripts/image.sh"
    interpreter = ["bash", "-c"]
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

  node_config {
    service_account = google_service_account.gke_service_account.email
    // preemptible     = true
    labels = {
      env = "dev"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable Shielded GKE Nodes with Secure Boot
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Enable GKE Metadata Server
    metadata = {
      "disable-legacy-endpoints" = "true"
      "gke-metadata-server"      = "enabled"
    }
  }
}

resource "kubernetes_service" "hello_world_service" {
  depends_on = []

  metadata {
    name      = "hello-world-service"
    namespace = "hello-world-ns"
    labels = {
      app = "hello-world"
    }

    annotations = {
      "cloud.google.com/load-balancer-type" = "External"
      //"cloud.google.com/backend-config"     = "gke-backend-config"
    }
  }

  spec {
    selector = {
      app = "hello-world"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "hello_world" {
  depends_on = []
  metadata {
    name      = "hello-world"
    namespace = "hello-world-ns"
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        /*
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 2000
        }
        */

        container {
          name              = "hello-world"
          image             = "gcr.io/gke-cluster-458701/hello-world:1.0.0@sha256:a25f725fdbe5223aed5a3cb6476aa6ac76297efdd45d953762dc6acd8b465f05"
          image_pull_policy = "Always"

          port {
            container_port = 80
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_namespace" "hello_world_ns" {
  metadata {
    name = "hello-world-ns"
  }
}


/*
resource "google_container_node_pool" "gke_pool" {
  depends_on = [
    google_project_service.api_services,
    google_service_account.gke_service_account
  ]
  name               = "gke-pool"
  cluster            = google_container_cluster.gke_cluster.name
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    service_account = google_service_account.gke_service_account.email
    preemptible     = true
    //machine_type    = "e2-medium"
    machine_type = "e2-micro"
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