locals {
  external_dns_name = "external-dns"
}

# EBS CSI as an EKS managed add-on
resource "aws_eks_addon" "external_dns" {
  cluster_name                = var.cluster_name
  addon_name                  = "external-dns"
  addon_version               = "v0.19.0-eksbuild.2"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    sources    = ["ingress"]
    policy     = "sync"
    registry   = "txt"
    txtOwnerId = var.cluster_name

    domainFilters = var.domain_filters

    managedRecordTypes = ["A"]

    logLevel           = "info" # "debug" for troubleshooting
    logFormat          = "json"
    interval           = "1m" # reconciliation interval
    triggerLoopOnEvent = true # react faster to changes (optional)
  })

  depends_on = [
    helm_release.lbc,
    aws_eks_pod_identity_association.lbc,
    aws_eks_addon.pod_identity_agent,
    aws_eks_pod_identity_association.external_dns
  ]
}

# resource "helm_release" "external-dns" {
#   name       = local.external_dns_name
#   namespace  = local.external_dns_name
#   repository = "https://kubernetes-sigs.github.io/external-dns/"
#   chart      = local.external_dns_name
#   version    = "1.19.0"

#   set = concat(
#     [
#       { name = "serviceAccount.create", value = "true" },
#       { name = "serviceAccount.name", value = local.external_dns_name },
#       { name = "sources[0]", value = "ingress" },
#       { name = "provider.name", value = "aws" },
#       { name = "policy", value = "upsert-only" },
#       { name = "registry", value = "txt" },
#       { name = "txtOwnerId", value = var.cluster_name },
#       { name = "aws.zoneType", value = "public" },
#       { name = "logEvents", value = "true" }
#     ],
#     [
#       for i, d in var.domain_filters :
#       { name = "domainFilters[${i}]", value = d }
#     ]
#   )

#   depends_on = [
#     aws_eks_pod_identity_association.external_dns,
#     helm_release.lbc,
#   ]
# }

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = var.cluster_name
  namespace       = local.external_dns_name
  service_account = local.external_dns_name
  role_arn        = aws_iam_role.external_dns.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.external_dns
  ]
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.sa_trust.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns-policy"
  policy = data.aws_iam_policy_document.external_dns.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
