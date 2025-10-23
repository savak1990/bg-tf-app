locals {
  # Hardcoded project and environment
  project     = "bg"
  environment = "dev"
  aws_region  = "eu-west-1"

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

  namespace           = "argocd"
  project_name        = "default-project"
  project_description = "Default project for applications"

  # Allow all repositories and destinations (adjust for production)
  source_repos = ["*"]

  destinations = [
    {
      namespace = "*"
      server    = "https://kubernetes.default.svc"
    }
  ]

  cluster_resource_whitelist = [
    {
      group = "*"
      kind  = "*"
    }
  ]

  namespace_resource_whitelist = [
    {
      group = "*"
      kind  = "*"
    }
  ]
}
