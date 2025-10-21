# Root Terragrunt configuration
# This file provides common settings inherited by all child terragrunt.hcl files

locals {
  # Parse the path to extract environment and region
  path_parts = split("/", get_terragrunt_dir())
  env        = path_parts[length(path_parts) - 2]  # e.g., "networking", "compute"
  region     = path_parts[length(path_parts) - 1]  # e.g., "eu-west-1"

  # Common variables
  project_name = "bg"
  aws_region   = local.region
  environment  = local.env

  # Common tags applied to all resources via provider default_tags
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Region      = local.aws_region
    ManagedBy   = "terragrunt"
    Repository  = "bg-tf-app"
  }
}

# Remote state backend configuration
remote_state {
  backend = "s3"

  config = {
    bucket         = "${local.project_name}-tf-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "${local.project_name}-tf-locks"
    skip_credentials_validation = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<-EOF
    terraform {
      required_version = ">= 1.10"
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 6.0"
        }
      }
    }

    provider "aws" {
      region = var.aws_region

      default_tags {
        tags = var.common_tags
      }
    }
  EOF
}

# Generate common variables
generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"

  contents = <<-EOF
    variable "aws_region" {
      description = "AWS region"
      type        = string
      default     = "${local.aws_region}"
    }

    variable "common_tags" {
      description = "Common tags applied to all resources"
      type        = map(string)
      default     = ${jsonencode(local.common_tags)}
    }
  EOF
}
