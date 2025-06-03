resource "kubernetes_namespace" "hello_world_ns" {
  depends_on = [
    google_container_cluster.gke_cluster,
    google_container_node_pool.gke_pool
  ]
  metadata {
    name = "hello-world-ns"
  }
}

resource "kubernetes_service" "hello_world_service" {
  depends_on = [kubernetes_namespace.hello_world_ns]
  metadata {
    name      = "hello-world-service"
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    labels = {
      app = "hello-world"
    }

    annotations = {
      "cloud.google.com/load-balancer-type" = "External"
    }
  }

  spec {
    selector = {
      app = "hello-world"
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
    name      = "hello-world"
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas                  = 2
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
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
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
          name              = "hello-world"
          image             = "gcr.io/gke-cluster-458701/hello-world:1.2.0@sha256:7b8ff6260e91e35964aa729c9aa2765066c85e03ccd6a2f500140b381f351935"
          image_pull_policy = "Always"

          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["NET_RAW", "ALL"]
            }
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