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

  # EKS configuration
  cluster_name  = "${local.project}-eks-${local.environment}"
  instance_type = "m5.large" # 2 vCPU, 8 GB RAM
  desired_size  = 3
  min_size      = 1
  max_size      = 5
}

# Data source to get networking outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/networking/terraform.tfstate"
    region = "eu-west-1"
  }
}

# EKS Cluster Module
module "eks" {
  source = "../../../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = "1.34"

  vpc_id     = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.public_subnet_ids

  # Node group configuration
  instance_type = local.instance_type
  desired_size  = local.desired_size
  min_size      = local.min_size
  max_size      = local.max_size
  disk_size     = 20

  # API endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  # Enable comprehensive cluster logging
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
