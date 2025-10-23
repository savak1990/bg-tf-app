# Quick Start: ArgoCD on EKS

## Architecture Philosophy

**Terraform manages:**
- ✅ EKS Cluster infrastructure
- ✅ ArgoCD installation (bootstrap only)

**ArgoCD manages (via GitOps):**
- ✅ All cluster addons (aws-load-balancer-controller, metrics-server, etc.)
- ✅ All applications
- ✅ Configuration and updates

This follows the **"Terraform bootstraps, ArgoCD operates"** pattern.

## What Was Created

1. **ArgoCD Terraform Module** (`modules/argocd/`)
   - Installs ArgoCD via Helm (bootstrap only)
   - Configures Kubernetes namespace
   - Sets up initial AppProject
   - **That's it!** Everything else managed by ArgoCD

2. **Integration with EKS** (`live/dev/eu-west-1/compute/`)
   - Kubernetes provider configured with EKS authentication
   - Helm provider configured with EKS authentication
   - ArgoCD module integrated with explicit dependencies

3. **Documentation**
   - `ARGOCD_BOOTSTRAP_GUIDE.md` - Complete GitOps guide
   - `modules/argocd/README.md` - Module documentation

## Deployment Steps

### 1. Review Configuration

Check the ArgoCD module call in `live/dev/eu-west-1/compute/main.tf`:

```hcl
module "argocd" {
  source = "../../../../modules/argocd"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate

  namespace     = "argocd"
  chart_version = "7.7.11"
  enable_ha     = false  # Set to true for production

  tags = local.common_tags
}
```

### 2. Initialize Terraform Providers

```bash
cd live/dev/eu-west-1/compute
terraform init -upgrade
```

This will download the new providers:
- `hashicorp/kubernetes` ~> 2.30
- `hashicorp/helm` ~> 2.14

### 3. Plan the Changes

```bash
terraform plan
```

You should see:
- ArgoCD namespace creation
- Helm release for ArgoCD
- Kubernetes manifest for AppProject

### 4. Apply

```bash
terraform apply
```

Or use the Makefile:
```bash
cd /Users/savak/Projects/BoardGameShop/bg-tf-app
make apply
```

**Expected duration:** ~5-10 minutes

### 5. Verify Installation

```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev

# Check ArgoCD pods
kubectl get pods -n argocd

# Expected output:
# NAME                                                READY   STATUS    RESTARTS
# argocd-application-controller-0                     1/1     Running   0
# argocd-applicationset-controller-xxx                1/1     Running   0
# argocd-dex-server-xxx                               1/1     Running   0
# argocd-notifications-controller-xxx                 1/1     Running   0
# argocd-redis-xxx                                    1/1     Running   0
# argocd-repo-server-xxx                              1/1     Running   0
# argocd-server-xxx                                   1/1     Running   0
```

### 6. Access ArgoCD

**Get admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

**Access UI via port-forward:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Open browser:**
```
https://localhost:8080
```

**Login:**
- Username: `admin`
- Password: (from command above)

### 7. Change Admin Password

After logging in:
1. Click **User Info** in the top right
2. Click **Update Password**
3. Set a new secure password

## What Happens During Apply

1. **EKS Cluster** - Already exists (no changes)
2. **Kubernetes Provider** - Connects to EKS cluster
3. **Helm Provider** - Connects to EKS cluster
4. **ArgoCD Namespace** - Created in cluster
5. **ArgoCD Helm Release** - Installs ArgoCD components
6. **ArgoCD AppProject** - Creates default project

**That's it!** Now ArgoCD will manage everything else from your GitOps repository.

## Terraform State

ArgoCD resources will be stored in your Terraform state:
- S3: `s3://bg-tf-state-vk/dev/eu-west-1/compute/terraform.tfstate`
- Resources:
  - `module.argocd.kubernetes_namespace.argocd`
  - `module.argocd.helm_release.argocd`
  - `module.argocd.kubernetes_manifest.argocd_project`

## Important Notes

### Provider Authentication

The Kubernetes and Helm providers use AWS CLI authentication:
```hcl
exec {
  api_version = "client.authentication.k8s.io/v1beta1"
  command     = "aws"
  args        = ["eks", "get-token", "--cluster-name", "bg-eks-dev", "--region", "eu-west-1"]
}
```

This means:
- ✅ Your AWS credentials must be valid
- ✅ You must have EKS cluster access
- ✅ No need to manage kubeconfig in Terraform

### Dependencies

ArgoCD module has explicit dependency on EKS module:
```hcl
depends_on = [module.eks]
```

This ensures EKS cluster is fully ready before installing ArgoCD.

### High Availability

Current configuration: `enable_ha = false` (single replica)

For production, set `enable_ha = true` to run:
- 2 replicas of argocd-server
- 2 replicas of argocd-application-controller
- 2 replicas of argocd-repo-server

### Service Type

Default: `LoadBalancer` (creates AWS ELB)

For production with ingress controller:
```hcl
ingress_enabled = true
ingress_host    = "argocd.yourdomain.com"
```

This will use ClusterIP service instead.

## Outputs

After apply, you'll see:

```
argocd_admin_password_command = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
argocd_namespace = "argocd"
argocd_port_forward_command = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
argocd_server_service = {
  "name" = "argocd-server"
  "type" = "LoadBalancer"
}
```

## Next Steps: GitOps Repository

Now that ArgoCD is installed, create a separate GitOps repository to manage everything else:

### Recommended Repository Structure

```
argocd-apps/
├── bootstrap/
│   ├── app-of-apps.yaml           # Root application
│   └── argocd-project.yaml        # ArgoCD project definition
├── infrastructure/
│   ├── aws-load-balancer-controller/
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   ├── metrics-server/
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   └── cert-manager/
│       ├── Chart.yaml
│       └── values.yaml
├── apps/
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── frontend/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
└── argocd-applications/
    ├── infrastructure.yaml         # Points to infrastructure/
    └── applications.yaml           # Points to apps/
```

### Quick Start GitOps Workflow

1. **Create a new Git repository** for ArgoCD applications
   ```bash
   git init argocd-apps
   cd argocd-apps
   ```

2. **Add the repository to ArgoCD**
   ```bash
   argocd repo add https://github.com/yourusername/argocd-apps \
     --username yourusername \
     --password yourtoken
   ```

3. **Deploy the App of Apps**
   ```bash
   kubectl apply -f bootstrap/app-of-apps.yaml
   ```

4. **Watch ArgoCD deploy everything**
   - Infrastructure components (load balancer controller, metrics-server)
   - Your applications
   - All automatically!

See `ARGOCD_BOOTSTRAP_GUIDE.md` for detailed GitOps repository setup!

## Why This Approach?

### ✅ Separation of Concerns
- **Terraform**: Infrastructure (VPC, EKS, ArgoCD bootstrap)
- **ArgoCD**: Everything in the cluster (addons, apps, config)

### ✅ GitOps Benefits
- All cluster resources version-controlled
- Easy rollback (just revert git commit)
- Audit trail (who changed what, when)
- Self-healing (ArgoCD auto-syncs from git)

### ✅ No Terraform Drift
- Terraform only manages ArgoCD installation
- No need to `terraform apply` for app deployments
- Faster iteration (git push vs terraform apply)

### ✅ Team Collaboration
- Developers can manage apps via git PRs
- Platform team manages infrastructure via Terraform
- Clear boundaries and responsibilities

## Example: Adding AWS Load Balancer Controller

**Old way (not recommended):**
```hcl
# In Terraform - requires terraform apply for every change
module "aws_lb_controller" {
  source = "..."
}
```

**New way (recommended):**
```yaml
# In GitOps repo - ArgoCD auto-deploys
# argocd-applications/aws-lb-controller.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-load-balancer-controller
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/yourusername/argocd-apps
    targetRevision: main
    path: infrastructure/aws-load-balancer-controller
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Just `git push` and ArgoCD deploys it!

## Customization

### Custom Helm Values

To customize ArgoCD installation, add `helm_values` parameter:

```hcl
module "argocd" {
  # ... other parameters

  helm_values = {
    server = {
      replicas = 3
      resources = {
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }
  }
}
```

### Custom Chart Version

To use a different ArgoCD version:

```hcl
chart_version = "7.7.11"  # ArgoCD v2.13.2
```

Check available versions: https://github.com/argoproj/argo-helm/releases

## Troubleshooting

### Provider Error

If you see:
```
Error: Kubernetes cluster unreachable
```

Solution:
```bash
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev
```

### Helm Release Timeout

If Helm release times out:
```bash
# Check pod status
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Can't Access LoadBalancer

If LoadBalancer is pending:
```bash
# Check service
kubectl get svc argocd-server -n argocd

# Use port-forward instead
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Clean Up (If Needed)

To remove ArgoCD:

```bash
# Option 1: Comment out module in main.tf and apply
terraform apply

# Option 2: Destroy specific resources
terraform destroy -target=module.argocd

# Option 3: Manual deletion
kubectl delete namespace argocd
```

⚠️ **Warning:** This will delete all ArgoCD Applications and their managed resources!

---

**Ready to deploy? Run `make apply`!** 🚀

**Next:** Create your GitOps repository and let ArgoCD manage everything else!
