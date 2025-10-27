locals {
  # Hardcoded project and environment
  project     = "bg"
  environment = "dev"
  aws_region  = "eu-west-1"
  apps_path   = "apps"

  # Common tags
  common_tags = {
    Project     = local.project
    Environment = local.environment
    Region      = local.aws_region
    ManagedBy   = "terraform"
    Repository  = "bg-tf-app"
  }
}

# Get authentication token for the cluster
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

# ArgoCD Configuration Module
# Note: This depends on ArgoCD being installed first (k8s-bootstrap)
module "k8s_argocd_config" {
  source = "../../../../modules/k8s-argocd-config"

  cluster_endpoint       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  cluster_auth_token     = data.aws_eks_cluster_auth.cluster.token

  namespace = "argocd"

  # Repository configuration for App-of-Apps
  repository_url   = "https://github.com/savak1990/bg-argocd-gitops.git"
  repository_name  = "bg-app-repo"
  app_of_apps_name = "bg-app-of-apps"
  apps_path        = local.apps_path
  target_revision  = "HEAD"
}
