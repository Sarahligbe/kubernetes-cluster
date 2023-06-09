# This is cluster wide so it'll cut across every namespace

resource "kubectl_manifest" "letsencrypt" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-dns
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: "${var.email}"
        privateKeySecretRef:
          name: letsencrypt-key-pair
        solvers:
          - dns01:
              route53:
                region: "${var.region}"
                hostedZoneID: "${data.aws_route53_zone.domain.zone_id}"
  YAML
   
  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "letsencrypt-certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
  namespace: "${kubernetes_namespace.cert_manager_ns.metadata[0].name}" 
spec:
  dnsNames:
  - "*.${var.domain}"
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  secretName: "${var.wildcard_secret_name}"
  commonName: "*.${var.domain}"
YAML

  depends_on = [kubectl_manifest.letsencrypt]
}
