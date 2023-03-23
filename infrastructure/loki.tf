resource "helm_release" "loki" {
  name = "my-loki-stack"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  version = "2.9.9"
  chart = "loki-stack"
  timeout = 1000
  repository = "https://grafana.github.io/helm-charts"

  set {
    name = "loki.isDefault"
    value = "false"
  }
 
  depends_on = [helm_release.monitoring]
}