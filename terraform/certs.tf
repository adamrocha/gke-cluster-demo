/*
resource "kubernetes_manifest" "gke_managed_cert" {
  depends_on = [google_container_cluster.gke_cluster]
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "hello-world-cert"
      namespace = "hello-world-ns"
    }
    spec = {
      domains = ["example.com"]
    }
  }
}

resource "kubernetes_ingress_v1" "demo_ingress" {
  depends_on = [google_container_cluster.gke_cluster, kubernetes_manifest.gke_managed_cert]
  metadata {
    name      = "demo-ingress"
    namespace = "hello-world-ns"
    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.gke_lb_ip.name
      "networking.gke.io/managed-certificates"      = kubernetes_manifest.gke_managed_cert.manifest["metadata"]["name"]
    }
  }

  spec {
    tls {
      secret_name = "not-needed" # TLS is handled by the managed cert
    }
    rule {
      host = "example.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.hello_world_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
*/