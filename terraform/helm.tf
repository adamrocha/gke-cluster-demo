resource "helm_release" "prometheus" {
  depends_on       = [google_container_node_pool.gke_pool]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600
  skip_crds        = false
  wait             = true

  set = [
    {
      name  = "prometheus.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "grafana.service.type"
      value = "LoadBalancer"
    }
  ]
}