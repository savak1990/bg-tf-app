terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "bg-tf-state-vk"
    key            = "dev/eu-west-1/eks-addons/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "bg-tf-state-locks"
  }
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Data source to get EKS cluster info from remote state
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/eks/terraform.tfstate"
    region = "eu-west-1"
  }
}
