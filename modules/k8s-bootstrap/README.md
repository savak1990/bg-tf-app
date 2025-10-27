# ArgoCD Terraform Module

This module installs and configures ArgoCD on an EKS cluster using Helm and Kubernetes providers.

## Features

- ✅ Installs ArgoCD using official Helm chart
- ✅ Creates dedicated namespace
- ✅ Configures initial AppProject
- ✅ Supports HA mode
- ✅ Optional ingress configuration
- ✅ LoadBalancer service by default (for easy access)
- ✅ Customizable Helm values

## Prerequisites

- EKS cluster must be running and accessible
- `kubectl` configured to access the cluster
- Terraform >= 1.0
- Kubernetes provider >= 2.30
- Helm provider >= 2.14

## Usage

```hcl
module "argocd" {
  source = "../../modules/argocd"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  
  namespace      = "argocd"
  chart_version  = "7.7.11"
  enable_ha      = false
  
  tags = var.tags
}
```

## Accessing ArgoCD

### Option 1: LoadBalancer (Default)

After installation, get the LoadBalancer URL:

```bash
kubectl get svc argocd-server -n argocd
```

Access via: `http://<EXTERNAL-IP>`

### Option 2: Port Forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access via: `https://localhost:8080`

### Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Default username: `admin`

## Configuring GitOps Repository

After ArgoCD is installed, you can configure it to watch your GitOps repository:

1. **Using ArgoCD CLI:**
```bash
argocd login <ARGOCD_SERVER>
argocd repo add https://github.com/your-org/gitops-repo.git --username <username> --password <token>
```

2. **Using Terraform (recommended):**
Add repository configuration to this module or create ArgoCD Application resources.

3. **Using App of Apps Pattern:**
Create a root Application that references other applications in your GitOps repo.

## High Availability

Enable HA mode for production:

```hcl
module "argocd" {
  source = "../../modules/argocd"
  # ... other variables
  
  enable_ha = true  # Runs 2 replicas of controller, server, and repo-server
}
```

## Custom Helm Values

Pass custom values to the Helm chart:

```hcl
module "argocd" {
  source = "../../modules/argocd"
  # ... other variables
  
  helm_values = {
    server = {
      replicas = 3
    }
    redis-ha = {
      enabled = true
    }
  }
}
```

## Security Considerations

- Default configuration runs in `--insecure` mode (HTTP) for easy local testing
- For production:
  - Enable TLS/HTTPS
  - Configure proper ingress with TLS certificates
  - Set up SSO/OIDC authentication
  - Use IRSA for AWS service access
  - Implement proper RBAC policies

## Outputs

- `namespace` - ArgoCD namespace
- `argocd_server_service_name` - Service name for ArgoCD server
- `admin_password_command` - Command to retrieve admin password
- `port_forward_command` - Command for local port forwarding

## Next Steps

1. Access ArgoCD UI
2. Change admin password
3. Add your GitOps repository
4. Create Applications to deploy your workloads
5. Set up App of Apps pattern for managing multiple applications

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
