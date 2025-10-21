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

  # VPC configuration
  vpc_name            = "${local.project}-vpc-${local.environment}"
  vpc_cidr            = "10.10.0.0/16"
  public_subnet_count = 2
}

# VPC Module
module "vpc" {
  source = "../../../../modules/vpc"

  vpc_name            = local.vpc_name
  vpc_cidr            = local.vpc_cidr
  public_subnet_count = local.public_subnet_count
}
