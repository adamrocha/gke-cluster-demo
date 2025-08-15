resource "helm_release" "prometheus" {
  depends_on       = [google_container_node_pool.gke_pool]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 600
  skip_crds        = false
  wait             = true

  set {
    name  = "grafana.enabled"
    value = "true"
  }
  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "grafana.service.port"
    value = "80"
  }
  set {
    name  = "alertmanager.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "prometheus.service.type"
    value = "ClusterIP"
  }
}