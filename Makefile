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
	@echo "  init                  - Initialize Terraform in all layers"
	@echo "  validate              - Validate Terraform configuration"
	@echo "  fmt                   - Format Terraform files"
	@echo "  plan                  - Show Terraform execution plan for all layers"
	@echo "  apply                 - Apply all infrastructure (VPC → EKS → EKS-Addons → K8s-Bootstrap → K8s-ArgoCD-Config) in sequence"
	@echo "  apply-vpc             - Apply VPC configuration only"
	@echo "  apply-eks             - Apply EKS configuration only (requires VPC)"
	@echo "  apply-eks-addons      - Apply EKS addons only (requires EKS)"
	@echo "  apply-k8s-bootstrap   - Apply K8s bootstrap (ArgoCD installation) only (requires EKS addons)"
	@echo "  apply-k8s-argocd      - Apply K8s ArgoCD configuration only (requires K8s bootstrap)"
	@echo "  destroy               - Destroy all Terraform-managed infrastructure"
	@echo "  destroy-k8s-argocd    - Destroy K8s ArgoCD configuration only"
	@echo "  destroy-k8s-bootstrap - Destroy K8s bootstrap only"
	@echo "  destroy-eks-addons    - Destroy EKS addons only"
	@echo "  destroy-eks           - Destroy EKS cluster only"
	@echo "  destroy-vpc           - Destroy VPC only (requires EKS to be destroyed first)"
	@echo "  clean                 - Clean Terraform cache and lock files"
	@echo "  output                - Show Terraform outputs"
	@echo "  creds-argocd          - Get ArgoCD initial admin password"
	@echo ""

# Terraform directories
TF_VPC_DIR            = live/dev/eu-west-1/networking
TF_EKS_DIR            = live/dev/eu-west-1/eks
TF_EKS_ADDONS_DIR     = live/dev/eu-west-1/eks-addons
TF_K8S_BOOTSTRAP_DIR  = live/dev/eu-west-1/k8s-bootstrap
TF_K8S_ARGOCD_DIR     = live/dev/eu-west-1/k8s-argocd-config

# Initialize Terraform
init:
	@echo "Initializing Terraform for VPC..."
	cd $(TF_VPC_DIR) && terraform init
	@echo ""
	@echo "Initializing Terraform for EKS..."
	cd $(TF_EKS_DIR) && terraform init
	@echo ""
	@echo "Initializing Terraform for EKS Addons..."
	cd $(TF_EKS_ADDONS_DIR) && terraform init
	@echo ""
	@echo "Initializing Terraform for K8s Bootstrap..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform init
	@echo ""
	@echo "Initializing Terraform for K8s ArgoCD Config..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform init

# Initialize VPC only
init-vpc:
	@echo "Initializing Terraform for VPC..."
	cd $(TF_VPC_DIR) && terraform init

# Initialize EKS only
init-eks:
	@echo "Initializing Terraform for EKS..."
	cd $(TF_EKS_DIR) && terraform init

# Initialize EKS Addons only
init-eks-addons:
	@echo "Initializing Terraform for EKS Addons..."
	cd $(TF_EKS_ADDONS_DIR) && terraform init

# Initialize K8s Bootstrap only
init-k8s-bootstrap:
	@echo "Initializing Terraform for K8s Bootstrap..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform init

# Initialize K8s ArgoCD Config only
init-k8s-argocd:
	@echo "Initializing Terraform for K8s ArgoCD Config..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform init

# Validate configuration
validate: init
	@echo "Validating VPC configuration..."
	cd $(TF_VPC_DIR) && terraform validate
	@echo ""
	@echo "Validating EKS configuration..."
	cd $(TF_EKS_DIR) && terraform validate
	@echo ""
	@echo "Validating EKS Addons configuration..."
	cd $(TF_EKS_ADDONS_DIR) && terraform validate
	@echo ""
	@echo "Validating K8s Bootstrap configuration..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform validate
	@echo ""
	@echo "Validating K8s ArgoCD Config configuration..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform validate

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
	@echo ""
	@echo "Creating Terraform execution plan for EKS Addons..."
	@echo "Note: EKS Addons plan will fail if EKS cluster doesn't exist yet."
	@cd $(TF_EKS_ADDONS_DIR) && terraform plan || echo "EKS Addons plan skipped (EKS not deployed yet)"
	@echo ""
	@echo "Creating Terraform execution plan for K8s Bootstrap..."
	@echo "Note: K8s Bootstrap plan will fail if EKS Addons aren't deployed yet."
	@cd $(TF_K8S_BOOTSTRAP_DIR) && terraform plan || echo "K8s Bootstrap plan skipped (EKS Addons not deployed yet)"
	@echo ""
	@echo "Creating Terraform execution plan for K8s ArgoCD Config..."
	@echo "Note: K8s ArgoCD Config plan will fail if K8s Bootstrap isn't deployed yet."
	@cd $(TF_K8S_ARGOCD_DIR) && terraform plan || echo "K8s ArgoCD Config plan skipped (K8s Bootstrap not deployed yet)"

# Plan VPC only
plan-vpc:
	@echo "Creating Terraform execution plan for VPC..."
	cd $(TF_VPC_DIR) && terraform plan

# Plan EKS only
plan-eks:
	@echo "Creating Terraform execution plan for EKS..."
	cd $(TF_EKS_DIR) && terraform plan

# Plan EKS Addons only
plan-eks-addons:
	@echo "Creating Terraform execution plan for EKS Addons..."
	cd $(TF_EKS_ADDONS_DIR) && terraform plan

# Plan K8s Bootstrap only
plan-k8s-bootstrap:
	@echo "Creating Terraform execution plan for K8s Bootstrap..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform plan

# Plan K8s ArgoCD Config only
plan-k8s-argocd:
	@echo "Creating Terraform execution plan for K8s ArgoCD Config..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform plan

# Apply configuration (VPC → EKS → EKS Addons → K8s Bootstrap → K8s ArgoCD Config)
apply: apply-vpc apply-eks apply-eks-addons apply-k8s-bootstrap apply-k8s-argocd
	@echo "All infrastructure applied successfully!"

# Apply VPC configuration
apply-vpc:
	@echo "Applying VPC configuration..."
	cd $(TF_VPC_DIR) && terraform apply -auto-approve

# Apply EKS configuration (depends on VPC)
apply-eks:
	@echo "Applying EKS configuration..."
	cd $(TF_EKS_DIR) && terraform apply -auto-approve

# Apply EKS Addons configuration (depends on EKS)
apply-eks-addons:
	@echo "Applying EKS Addons configuration..."
	cd $(TF_EKS_ADDONS_DIR) && terraform apply -auto-approve

# Apply K8s Bootstrap configuration (depends on EKS Addons)
apply-k8s-bootstrap:
	@echo "Applying K8s Bootstrap configuration (ArgoCD)..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform apply -auto-approve

# Apply K8s ArgoCD Config configuration (depends on K8s Bootstrap)
apply-k8s-argocd:
	@echo "Applying K8s ArgoCD Config configuration..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform apply -auto-approve

# Apply with manual approval
apply-confirm: init
	@echo "Applying VPC configuration (with confirmation)..."
	cd $(TF_VPC_DIR) && terraform apply
	@echo ""
	@echo "Applying EKS configuration (with confirmation)..."
	cd $(TF_EKS_DIR) && terraform apply
	@echo ""
	@echo "Applying EKS Addons configuration (with confirmation)..."
	cd $(TF_EKS_ADDONS_DIR) && terraform apply
	@echo ""
	@echo "Applying K8s Bootstrap configuration (with confirmation)..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform apply
	@echo ""
	@echo "Applying K8s ArgoCD Config configuration (with confirmation)..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform apply

# Destroy infrastructure (K8s ArgoCD Config → K8s Bootstrap → EKS Addons → EKS → VPC)
destroy: destroy-k8s-argocd destroy-k8s-bootstrap destroy-eks-addons destroy-eks destroy-vpc
	@echo "All infrastructure destroyed!"

# Destroy K8s ArgoCD Config
destroy-k8s-argocd:
	@echo "Destroying K8s ArgoCD configuration..."
	cd $(TF_K8S_ARGOCD_DIR) && terraform destroy -auto-approve

# Destroy K8s Bootstrap
destroy-k8s-bootstrap:
	@echo "Destroying K8s Bootstrap..."
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform destroy -auto-approve

# Destroy EKS Addons
destroy-eks-addons:
	@echo "Destroying EKS Addons..."
	cd $(TF_EKS_ADDONS_DIR) && terraform destroy -auto-approve

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
	@echo ""
	@echo "EKS Addons Terraform outputs:"
	@echo "============================="
	cd $(TF_EKS_ADDONS_DIR) && terraform output
	@echo ""
	@echo "K8s Bootstrap Terraform outputs:"
	@echo "================================"
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform output
	@echo ""
	@echo "K8s ArgoCD Config Terraform outputs:"
	@echo "===================================="
	cd $(TF_K8S_ARGOCD_DIR) && terraform output

# Show VPC outputs only
output-vpc:
	@echo "VPC Terraform outputs:"
	cd $(TF_VPC_DIR) && terraform output

# Show EKS outputs only
output-eks:
	@echo "EKS Terraform outputs:"
	cd $(TF_EKS_DIR) && terraform output

# Show EKS Addons outputs only
output-eks-addons:
	@echo "EKS Addons Terraform outputs:"
	cd $(TF_EKS_ADDONS_DIR) && terraform output

# Show K8s Bootstrap outputs only
output-k8s-bootstrap:
	@echo "K8s Bootstrap Terraform outputs:"
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform output

# Show K8s ArgoCD Config outputs only
output-k8s-argocd:
	@echo "K8s ArgoCD Config Terraform outputs:"
	cd $(TF_K8S_ARGOCD_DIR) && terraform output

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
	@echo ""
	@echo "EKS Addons Terraform state:"
	@echo "==========================="
	cd $(TF_EKS_ADDONS_DIR) && terraform state list
	@echo ""
	@echo "K8s Bootstrap Terraform state:"
	@echo "=============================="
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform state list
	@echo ""
	@echo "K8s ArgoCD Config Terraform state:"
	@echo "=================================="
	cd $(TF_K8S_ARGOCD_DIR) && terraform state list

# Show VPC state only
state-vpc:
	@echo "VPC Terraform state:"
	cd $(TF_VPC_DIR) && terraform state list

# Show EKS state only
state-eks:
	@echo "EKS Terraform state:"
	cd $(TF_EKS_DIR) && terraform state list

# Show EKS Addons state only
state-eks-addons:
	@echo "EKS Addons Terraform state:"
	cd $(TF_EKS_ADDONS_DIR) && terraform state list

# Show K8s Bootstrap state only
state-k8s-bootstrap:
	@echo "K8s Bootstrap Terraform state:"
	cd $(TF_K8S_BOOTSTRAP_DIR) && terraform state list

# Show K8s ArgoCD Config state only
state-k8s-argocd:
	@echo "K8s ArgoCD Config Terraform state:"
	cd $(TF_K8S_ARGOCD_DIR) && terraform state list

# Get ArgoCD initial admin password
creds-argocd:
	@echo "Fetching ArgoCD url, login and password..."
	ARGOCD_URL=$$(kubectl -n argocd get svc argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"); \
	ARGOCD_ADMIN_PASSWORD=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode); \
	ARGOCD_PORT_FORWARD_COMMAND=$$(cd $(TF_K8S_BOOTSTRAP_DIR) && terraform output -raw argocd_port_forward_command); \
	echo "Port Forward Command: $$ARGOCD_PORT_FORWARD_COMMAND"; \
	echo "ArgoCD URL: $$ARGOCD_URL"; \
	echo "Admin Username: admin"; \
	echo "Admin Password: $$ARGOCD_ADMIN_PASSWORD"; \
