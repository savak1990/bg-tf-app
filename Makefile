# Makefile for BoardGameShop Terraform Infrastructure
# Usage: make <target>

.PHONY: help init plan apply destroy validate fmt clean

# Default target
help:
	@echo "BoardGameShop Terraform Commands"
	@echo "================================="
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  init           - Initialize Terraform in both networking and compute"
	@echo "  validate       - Validate Terraform configuration"
	@echo "  fmt            - Format Terraform files"
	@echo "  plan           - Show Terraform execution plan for all modules"
	@echo "  apply          - Apply all infrastructure (VPC then EKS)"
	@echo "  apply-vpc      - Apply VPC configuration only"
	@echo "  apply-eks      - Apply EKS configuration only (requires VPC)"
	@echo "  destroy        - Destroy all Terraform-managed infrastructure"
	@echo "  destroy-eks    - Destroy EKS cluster only"
	@echo "  destroy-vpc    - Destroy VPC only (requires EKS to be destroyed first)"
	@echo "  clean          - Clean Terraform cache and lock files"
	@echo "  output         - Show Terraform outputs"
	@echo ""

# Terraform directories
TF_VPC_DIR = live/dev/eu-west-1/networking
TF_EKS_DIR = live/dev/eu-west-1/compute

# Initialize Terraform
init:
	@echo "Initializing Terraform for VPC..."
	cd $(TF_VPC_DIR) && terraform init
	@echo ""
	@echo "Initializing Terraform for EKS..."
	cd $(TF_EKS_DIR) && terraform init

# Initialize VPC only
init-vpc:
	@echo "Initializing Terraform for VPC..."
	cd $(TF_VPC_DIR) && terraform init

# Initialize EKS only
init-eks:
	@echo "Initializing Terraform for EKS..."
	cd $(TF_EKS_DIR) && terraform init

# Validate configuration
validate: init
	@echo "Validating VPC configuration..."
	cd $(TF_VPC_DIR) && terraform validate
	@echo ""
	@echo "Validating EKS configuration..."
	cd $(TF_EKS_DIR) && terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Create execution plan
plan: init
	@echo "Creating Terraform execution plan for VPC..."
	cd $(TF_VPC_DIR) && terraform plan
	@echo ""
	@echo "Creating Terraform execution plan for EKS..."
	cd $(TF_EKS_DIR) && terraform plan

# Plan VPC only
plan-vpc: init-vpc
	@echo "Creating Terraform execution plan for VPC..."
	cd $(TF_VPC_DIR) && terraform plan

# Plan EKS only
plan-eks: init-eks
	@echo "Creating Terraform execution plan for EKS..."
	cd $(TF_EKS_DIR) && terraform plan

# Apply configuration (VPC first, then EKS)
apply: apply-vpc apply-eks
	@echo "All infrastructure applied successfully!"

# Apply VPC configuration
apply-vpc: init-vpc
	@echo "Applying VPC configuration..."
	cd $(TF_VPC_DIR) && terraform apply -auto-approve

# Apply EKS configuration (depends on VPC)
apply-eks: init-eks apply-vpc
	@echo "Applying EKS configuration..."
	cd $(TF_EKS_DIR) && terraform apply -auto-approve

# Apply with manual approval
apply-confirm: init
	@echo "Applying VPC configuration (with confirmation)..."
	cd $(TF_VPC_DIR) && terraform apply
	@echo ""
	@echo "Applying EKS configuration (with confirmation)..."
	cd $(TF_EKS_DIR) && terraform apply

# Destroy infrastructure (EKS first, then VPC)
destroy: destroy-eks destroy-vpc
	@echo "All infrastructure destroyed!"

# Destroy EKS cluster
destroy-eks:
	@echo "Destroying EKS cluster..."
	cd $(TF_EKS_DIR) && terraform destroy -auto-approve

# Destroy VPC (should be done after EKS is destroyed)
destroy-vpc:
	@echo "Destroying VPC..."
	cd $(TF_VPC_DIR) && terraform destroy -auto-approve

# Show outputs
output:
	@echo "VPC Terraform outputs:"
	@echo "======================"
	cd $(TF_VPC_DIR) && terraform output
	@echo ""
	@echo "EKS Terraform outputs:"
	@echo "======================"
	cd $(TF_EKS_DIR) && terraform output

# Show VPC outputs only
output-vpc:
	@echo "VPC Terraform outputs:"
	cd $(TF_VPC_DIR) && terraform output

# Show EKS outputs only
output-eks:
	@echo "EKS Terraform outputs:"
	cd $(TF_EKS_DIR) && terraform output

# Clean Terraform files
clean:
	@echo "Cleaning Terraform cache and lock files..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

# Show current state
state:
	@echo "VPC Terraform state:"
	@echo "===================="
	cd $(TF_VPC_DIR) && terraform state list
	@echo ""
	@echo "EKS Terraform state:"
	@echo "===================="
	cd $(TF_EKS_DIR) && terraform state list

# Show VPC state only
state-vpc:
	@echo "VPC Terraform state:"
	cd $(TF_VPC_DIR) && terraform state list

# Show EKS state only
state-eks:
	@echo "EKS Terraform state:"
	cd $(TF_EKS_DIR) && terraform state list
