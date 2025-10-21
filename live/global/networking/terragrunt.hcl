# Terragrunt configuration for shared networking resources
# This file is inherited by all networking module configurations

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  # Local variable overrides for this specific component
  vpc_config = {
    vpc_cidr            = "10.0.0.0/16"
    public_subnet_count = 2
  }
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

# Generate inputs file for Terraform variables
generate "terraform_variables" {
  path      = "terraform.auto.tfvars"
  if_exists = "overwrite"

  contents = <<-EOF
    vpc_name            = "bg-shared-vpc"
    vpc_cidr            = "${local.vpc_config.vpc_cidr}"
    public_subnet_count = ${local.vpc_config.public_subnet_count}
  EOF
}

# Dependency management - currently no dependencies
# When you add compute/EKS later, you can add dependencies here
# dependencies {
#   paths = ["../../../compute/eu-west-1"]
# }

# Mock outputs for testing (optional)
skip = false
