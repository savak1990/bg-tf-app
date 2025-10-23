terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  backend "s3" {
    bucket         = "bg-tf-state-vk"
    key            = "dev/eu-west-1/charts-config/terraform.tfstate"
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
    key    = "dev/eu-west-1/compute/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Get ArgoCD installation data from remote state
data "terraform_remote_state" "argocd_install" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/charts/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Kubernetes provider configuration
# This provider will use the EKS cluster endpoint and authentication
provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.eks.outputs.cluster_name,
      "--region",
      local.aws_region
    ]
  }
}
