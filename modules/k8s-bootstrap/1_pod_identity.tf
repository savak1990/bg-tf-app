# EKS Pod Identity Agent (required for Pod Identity)
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.3.9-eksbuild.3"
  resolve_conflicts_on_update = "OVERWRITE"
}
