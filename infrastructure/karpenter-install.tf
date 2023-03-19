data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "kubernetes_namespace" "karpenter_ns" {
  metadata {
    name = "karpenter"
  }
}

resource "helm_release" "karpenter" {
  namespace        = kubernetes_namespace.karpenter_ns.metadata[0].name
  timeout = 1000

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.16.3"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_role.arn 
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name 
    #module.karpenter.instance_profile_name
  }

 # set {
 #   name  = "settings.aws.interruptionQueueName"
 #   value = module.karpenter.queue_name
 # }

  depends_on = [module.eks, kubernetes_namespace.karpenter_ns]
}

resource "kubectl_manifest" "karpenter-provisioner" {
  yaml_body = <<-YAML
    apiVersion:  karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      ttlSecondsAfterEmpty: 60
      requirements: 
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: [t2, t3, t3a]
        - key: "karpenter.k8s.aws/instance-size"
          operator: NotIn
          values: [nano, micro, small, large,  xlarge, 2xlarge]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["us-east-1a", "us-east-1b"]
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: "topology.kubernetes.io/zone"
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              scale: yes
        - maxSkew: 1
          topologyKey: "kubernetes.io/hostname"
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              scale: yes
      limits:
        resources:
          cpu: 25
      providerRef:
        name: default
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        kubernetes.io/cluster/${module.eks.cluster_name}: owned
      securityGroupSelector:
        kubernetes.io/cluster/${module.eks.cluster_name}: owned
    tags:
      karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [helm_release.karpenter]
}
