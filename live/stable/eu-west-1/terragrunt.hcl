# Terragrunt configuration for development environment

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

# Development environment uses the shared networking
dependency "networking" {
  config_path = "../../global/networking/eu-west-1"
  
  mock_outputs = {
    vpc_id             = "vpc-12345678"
    public_subnet_ids  = ["subnet-12345678", "subnet-87654321"]
    vpc_cidr_block     = "10.0.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  # Point to compute module when ready
  # For now, this is a placeholder
  source = "."
}

# When you add compute/EKS here, it will use:
inputs = {
  vpc_id             = dependency.networking.outputs.vpc_id
  public_subnet_ids  = dependency.networking.outputs.public_subnet_ids
  vpc_cidr_block     = dependency.networking.outputs.vpc_cidr_block

  environment = "dev"
}
