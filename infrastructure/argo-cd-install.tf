resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd-helm" {
  name = "argo-cd"
  namespace = kubernetes_namespace.argo-cd.metadata[0].name
  version = "5.27.0"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  timeout = 1000

  values = [templatefile("argo-cd-values.yaml", {slack = "${var.argoslack}", domain = "${var.argocd-domain}", argocdpass = "${var.argocdpass}"})]

  depends_on = [module.eks, helm_release.ingress, kubernetes_namespace.argo-cd]
}

resource "kubectl_manifest" "argocd-ingress" {
  yaml_body = <<YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-ingress
      namespace: argocd
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-dns
        kubernetes.io/tls-acme: "true"
        nginx.ingress.kubernetes.io/backend-protocol: HTTPS
        nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    spec:
      ingressClassName: nginx
      tls:
        - hosts:
            - "*.${var.domain}"
          secretName: wildcard-cert
      rules:
        - host: "${var.argocd-domain}"
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argo-cd-argocd-server
                    port: 
                      number: 80
  YAML

  depends_on = [helm_release.argocd-helm]
}

resource "kubectl_manifest" "applicationset" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-tenancy
  namespace: argocd
spec: 
  generators: 
    - git: 
        repoURL: https://github.com/Sarahligbe/kubernetes-cluster.git
        revision: HEAD
        directories: 
          - path: k8s/*
  template: 
    metadata: 
      name: '{{path.basename}}'
      annotations:
        notifications.argoproj.io/subscribe.on-sync-succeeded.slack: argocd-build
        notifications.argoproj.io/subscribe.on-sync-failed.slack: argocd-build
        notifications.argoproj.io/subscribe.on-health-degraded: argocd-build
        notifications.argoproj.io/subscribe.on-deployed.slack: argocd-build

    spec: 
      project: default
      source: 
        repoURL: https://github.com/Sarahligbe/kubernetes-cluster.git
        targetRevision: HEAD
        path: '{{path}}'
      destination: 
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      syncPolicy: 
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    kubectl_manifest.argocd-ingress
  ]
}
