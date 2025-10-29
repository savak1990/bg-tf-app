# Metrics Server add-on
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = var.cluster_name
  addon_name                  = "metrics-server"
  addon_version               = "v0.8.0-eksbuild.2"
  resolve_conflicts_on_update = "OVERWRITE"

  // Seems like metrics-server add has indirect dependency on aws-load-balancer-controller
  depends_on = [
    helm_release.lbc
  ]
}
