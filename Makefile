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
	@echo "  init      - Initialize Terraform in dev/eu-west-1/networking"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  plan      - Show Terraform execution plan"
	@echo "  apply     - Apply Terraform configuration (creates VPC)"
	@echo "  destroy   - Destroy all Terraform-managed infrastructure"
	@echo "  clean     - Clean Terraform cache and lock files"
	@echo "  output    - Show Terraform outputs"
	@echo ""

# Terraform directory
TF_DIR = live/dev/eu-west-1/networking

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	cd $(TF_DIR) && terraform init

# Validate configuration
validate: init
	@echo "Validating Terraform configuration..."
	cd $(TF_DIR) && terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Create execution plan
plan: init
	@echo "Creating Terraform execution plan..."
	cd $(TF_DIR) && terraform plan

# Apply configuration
apply: init
	@echo "Applying Terraform configuration..."
	cd $(TF_DIR) && terraform apply -auto-approve

# Apply with manual approval
apply-confirm: init
	@echo "Applying Terraform configuration (with confirmation)..."
	cd $(TF_DIR) && terraform apply

# Destroy infrastructure
destroy:
	@echo "Destroying Terraform infrastructure..."
	cd $(TF_DIR) && terraform destroy -auto-approve

# Show outputs
output:
	@echo "Terraform outputs:"
	cd $(TF_DIR) && terraform output

# Clean Terraform files
clean:
	@echo "Cleaning Terraform cache and lock files..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

# Show current state
state:
	@echo "Terraform state list:"
	cd $(TF_DIR) && terraform state list
