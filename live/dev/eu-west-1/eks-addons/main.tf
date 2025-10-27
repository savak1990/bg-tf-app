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

# Get authentication token for the cluster
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

# EKS Addons Module
module "eks_addons" {
  source = "../../../../modules/eks-addons"

  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  cluster_auth_token     = data.aws_eks_cluster_auth.cluster.token
}

