# Variables for VPC Module

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets to create (across available AZs)"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count > 0 && var.public_subnet_count <= 3
    error_message = "public_subnet_count must be between 1 and 3."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
