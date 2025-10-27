# Charts Layer - Helm Installations

This layer manages Helm chart installations on the EKS cluster using Terraform.

## Purpose

- Installs and manages Kubernetes applications via Helm charts
- Currently deploys ArgoCD for GitOps workflows
- Can be extended for other cluster addons (metrics-server, cert-manager, etc.)

## Prerequisites

- EKS cluster must exist (run `make apply-eks` first)
- `kubectl` configured to access the cluster
- AWS credentials configured

## Structure

```
charts/
├── main.tf       # Module calls and resources
├── provider.tf   # Provider configurations (Kubernetes, Helm)
├── outputs.tf    # Outputs for chart installations
└── README.md     # This file
```

## Current Deployments

### ArgoCD
- **Namespace**: `argocd`
- **Chart Version**: 7.7.11 (ArgoCD v2.13.2)
- **Purpose**: GitOps continuous delivery for Kubernetes

## Usage

### Deploy all charts
```bash
make apply-charts
```

### Or manually
```bash
cd live/dev/eu-west-1/charts
terraform init
terraform plan
terraform apply
```

### View outputs
```bash
make output-charts
```

## Dependencies

This layer depends on:
- **VPC layer** (`live/dev/eu-west-1/networking`) - for network resources
- **EKS layer** (`live/dev/eu-west-1/compute`) - for cluster endpoint and authentication

Uses Terraform remote state to fetch EKS cluster information.

## Adding New Charts

To add a new Helm chart:

1. Add the module call to `main.tf`
2. Configure providers if needed
3. Add outputs to `outputs.tf`
4. Run `terraform plan` and `terraform apply`

Example:
```hcl
module "metrics_server" {
  source = "../../../../modules/metrics-server"
  
  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_id
  cluster_endpoint       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  
  tags = local.common_tags
}
```

## Important Notes

### Why Separate Layer?

Separating charts from the EKS layer solves the "chicken and egg" problem:
- EKS cluster must exist before Kubernetes/Helm providers can connect
- Terraform evaluates providers during initialization
- By separating layers, EKS is created first, then charts are applied

### GitOps Philosophy

While Terraform manages ArgoCD installation, **ArgoCD should manage everything else**:
- ✅ Terraform: Bootstrap ArgoCD
- ✅ ArgoCD: Manage all other controllers and applications from Git

This follows the "Terraform bootstraps, ArgoCD operates" pattern.

## Troubleshooting

### Provider Connection Errors

If you see errors about connecting to the cluster:
```bash
# Ensure EKS cluster exists
make output-eks

# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev

# Verify connectivity
kubectl get nodes
```

### Helm Release Failures

Check Helm release status:
```bash
helm ls -n argocd
kubectl get pods -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### State Issues

If state gets out of sync:
```bash
cd live/dev/eu-west-1/charts
terraform refresh
terraform plan
```

## Clean Up

To remove all charts:
```bash
make destroy-charts
```

Or manually:
```bash
cd live/dev/eu-west-1/charts
terraform destroy
```

**Warning**: This will delete ArgoCD and all Applications it manages!
