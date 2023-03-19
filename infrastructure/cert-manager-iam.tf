locals {
  full_service_account_name = "${var.chartname}-${var.cert_manager_sa}"
}

resource "aws_iam_policy" "cert_manager_route53_access" {
  name = "cert-manager-policy"
  description = "Cert manager IAM Policy for SSL"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
    {
      Effect = "Allow"
      Action = ["route53:GetChange"]
      Resource = "arn:aws:route53:::change/*"
    },
    {
    Effect = "Allow"
    Action = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
    Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.domain.zone_id}"
    }
   ]
})
}

data "aws_iam_policy_document" "cert_manager_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${kubernetes_namespace.cert_manager_ns.metadata[0].name}:${var.cert_manager_sa}"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cert_manager_role" {
  name = "cert-manager-acme"

  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cert_manager_role_attach" {
  role = aws_iam_role.cert_manager_role.name
  policy_arn = aws_iam_policy.cert_manager_route53_access.arn
}
