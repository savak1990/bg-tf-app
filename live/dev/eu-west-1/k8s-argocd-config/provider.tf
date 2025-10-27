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
    key            = "dev/eu-west-1/k8s-argocd-config/terraform.tfstate"
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

# Get EKS cluster data from remote state
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/eks/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Get ArgoCD installation data from remote state
data "terraform_remote_state" "k8s_bootstrap" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/k8s-bootstrap/terraform.tfstate"
    region = "eu-west-1"
  }
}
