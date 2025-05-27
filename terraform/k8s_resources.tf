resource "kubernetes_namespace" "hello_world_ns" {
  metadata {
    name = "hello-world-ns"
  }
}

resource "kubernetes_service" "hello_world_service" {
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
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "hello_world" {
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
    progress_deadline_seconds = 600
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
          run_as_non_root = false
        }

        container {
          name              = "hello-world"
          image             = "gcr.io/gke-cluster-458701/hello-world:1.0.0@sha256:1eb501d45bf85b69c6e235c70db971872d82d956a8cd0ab875002894270ff65b"
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