# CloudWatch Observability Addon
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = var.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = "v4.5.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    helm_release.lbc,
    aws_eks_pod_identity_association.cloudwatch_observability
  ]
}

# Explicit Pod Identity Association for CloudWatch Observability
resource "aws_eks_pod_identity_association" "cloudwatch_observability" {
  cluster_name    = var.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cw_agent_role.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.cw_agent_policy
  ]
}

# IAM Role for service account responsible for CloudWatch Agent
resource "aws_iam_role" "cw_agent_role" {
  name               = "${var.cluster_name}-cloudwatch-agent-role"
  assume_role_policy = data.aws_iam_policy_document.sa_trust.json
}

# Policy that allows to upload logs, metrics, etc
resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
