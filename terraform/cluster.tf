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

data "google_container_cluster" "primary" {
  name = google_container_cluster.gke_cluster.name
}

resource "google_container_cluster" "gke_cluster" {
  depends_on = [
    google_project_service.api_services,
    google_service_account.gke_service_account,
    google_project_iam_member.gke_sa_roles
  ]
  name             = "gke-cluster"
  enable_autopilot = true
  network          = google_compute_network.gke_vpc.name
  subnetwork       = google_compute_subnetwork.gke_subnet.name
  //remove_default_node_pool = true
  initial_node_count  = 1
  deletion_protection = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }

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

resource "kubernetes_service" "hello_world_service" {
  depends_on = [data.google_container_cluster.primary]
  //  depends_on = [google_container_node_pool.gke_pool]

  metadata {
    name = "hello-world-service"
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
  depends_on = [kubernetes_service.hello_world_service]
  metadata {
    name = "hello-world"
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
        container {
          name  = "hello-world"
          image = var.kubernetes_image

          port {
            container_port = 80
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
