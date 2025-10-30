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
    key            = "dev/eu-west-1/k8s-bootst/terraform.tfstate"
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
