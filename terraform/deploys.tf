resource "kubernetes_namespace" "hello_world_ns" {
  depends_on = [
    google_container_cluster.gke_cluster,
    google_container_node_pool.gke_pool
  ]
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service" "hello_world_service" {
  depends_on = [kubernetes_namespace.hello_world_ns]
  metadata {
    name      = var.service
    namespace = var.namespace
    labels = {
      app = var.deployment
    }

    annotations = {
      "cloud.google.com/load-balancer-type" = "External"
    }
  }

  spec {
    selector = {
      app = var.deployment
    }

    type = "LoadBalancer"

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "hello_world" {
  depends_on = [kubernetes_namespace.hello_world_ns]
  metadata {
    name      = var.deployment
    namespace = var.namespace
    labels = {
      app = var.deployment
    }
  }

  spec {
    replicas                  = 3
    revision_history_limit    = 10
    min_ready_seconds         = 5
    progress_deadline_seconds = 300

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    selector {
      match_labels = {
        app = var.deployment
      }
    }

    template {
      metadata {
        labels = {
          app = var.deployment
        }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 10001
        }

        volume {
          name = "nginx-cache"
          empty_dir {}
        }

        volume {
          name = "nginx-run"
          empty_dir {}
        }

        container {
          name              = var.deployment
          image             = "gcr.io/${var.project_id}/${var.repo_name}:${var.image_tag}@${var.image_digest}"
          image_pull_policy = "Always"

          security_context {
            run_as_non_root            = true
            run_as_user                = 10001
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["NET_RAW", "ALL"]
            }
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }

          volume_mount {
            name       = "nginx-run"
            mount_path = "/var/run"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}