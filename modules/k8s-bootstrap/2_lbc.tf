locals {
  aws_lbc_name = "aws-load-balancer-controller"
}

# Ingress Controller and Application Load Balancer
# Seems like there is no official EKS managed addon (installing with helm)
resource "helm_release" "lbc" {
  name = local.aws_lbc_name

  repository = "https://aws.github.io/eks-charts"
  chart      = local.aws_lbc_name
  namespace  = "kube-system"
  version    = "1.14.1"

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "serviceAccount.name", value = local.aws_lbc_name },
    { name = "region", value = data.aws_region.current.region },
    { name = "vpcId", value = var.cluster_vpc_id }
  ]

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_pod_identity_association.lbc,
    aws_iam_role_policy_attachment.lbc
  ]
}

# Associate pod identity service account with IAM role
resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = local.aws_lbc_name
  role_arn        = aws_iam_role.lbc.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.lbc
  ]
}

# IAM Role for ingress controller
resource "aws_iam_role" "lbc" {
  name               = "${var.cluster_name}-lbc-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.sa_trust.json
}

# Define the policy
resource "aws_iam_policy" "lbc" {
  name   = "${var.cluster_name}-lbc-policy"
  policy = file("${path.module}/iam/aws-load-balancer-controller.json")
}

# Access required to create Load Balancers
resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}
