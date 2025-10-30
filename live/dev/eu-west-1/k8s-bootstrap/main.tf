# Data source to get EKS cluster info from remote state
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/eks/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Get authentication token for the cluster
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_ssm_parameter" "domain" {
  name = "/bg-app/dev/domain"
}

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

# EKS Addons Module
module "k8s_bootstrap" {
  source = "../../../../modules/k8s-bootstrap"

  cluster_vpc_id         = data.terraform_remote_state.eks.outputs.cluster_vpc_id
  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  cluster_auth_token     = data.aws_eks_cluster_auth.cluster.token
  domain_filters         = [data.aws_ssm_parameter.domain.value]
}

