resource "kubernetes_namespace" "cert_manager_ns" {
   metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  namespace        = kubernetes_namespace.cert_manager_ns.metadata[0].name
  timeout = 1000
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = var.chartname
  version = "v1.11.0"

  create_namespace = false

  values = [yamlencode({
   "installCRDs": "true",
   "prometheus": {
      "enabled": "true"
   },
   "serviceAccount": {
    "name": var.cert_manager_sa,
    "annotations": {
       "eks.amazonaws.com/role-arn": aws_iam_role.cert_manager_role.arn
   }
   },
   "securityContext": {"fsGroup":1001}
  })]

  depends_on = [module.eks, kubernetes_namespace.cert_manager_ns, aws_iam_role.cert_manager_role ]

}
