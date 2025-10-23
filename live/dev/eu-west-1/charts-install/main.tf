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

# ArgoCD Module
# Note: EKS remote state is accessed via data source in provider.tf
module "argocd" {
  source = "../../../../modules/argocd-install"

  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data

  namespace     = "argocd"
  chart_version = "7.7.11" # ArgoCD v2.13.2
  enable_ha     = false    # Set to true for production

  # Optional: Enable ingress (requires ingress controller)
  ingress_enabled = false
  # ingress_host    = "argocd.example.com"

  # Pass OIDC provider ARN for IRSA (optional)
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn

  tags = local.common_tags
}
