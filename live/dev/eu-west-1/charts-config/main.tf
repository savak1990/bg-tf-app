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

# ArgoCD Configuration Module
# Note: This depends on ArgoCD being installed first (charts-install)
module "argocd_config" {
  source = "../../../../modules/argocd-conf"

  namespace = "argocd"

  # Repository configuration for App-of-Apps
  repository_url   = "https://github.com/savak1990/bg-argocd-gitops.git"
  repository_name  = "bg-app-repo"
  app_of_apps_name = "bg-app-of-apps"
  apps_path        = local.apps_path
  target_revision  = "HEAD"
}
