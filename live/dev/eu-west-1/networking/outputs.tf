locals {
  # only the AZs that correspond to created public subnets
  azs_used = slice(module.vpc.availability_zones, 0, length(module.vpc.public_subnet_ids))

  # structured list of created public subnets with id, cidr and az
  public_subnets = [
    for i in range(length(module.vpc.public_subnet_ids)) : {
      id   = module.vpc.public_subnet_ids[i]
      cidr = module.vpc.public_subnet_cidrs[i]
      az   = local.azs_used[i]
    }
  ]
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = local.vpc_name
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnet_cidrs
}

output "public_subnets" {
  description = "Structured list of created public subnets (id, cidr, az)"
  value       = local.public_subnets
}

output "availability_zones" {
  description = "List of availability zones actually used for public subnets"
  value       = local.azs_used
}

output "region" {
  description = "AWS region"
  value       = local.aws_region
}

output "environment" {
  description = "Environment name"
  value       = local.environment
}
