# ArgoCD Bootstrap Guide

This guide walks you through deploying ArgoCD on your EKS cluster using Terraform and setting up GitOps workflows.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Accessing ArgoCD](#accessing-argocd)
6. [Setting Up GitOps Repository](#setting-up-gitops-repository)
7. [App of Apps Pattern](#app-of-apps-pattern)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This setup:

- ✅ Installs ArgoCD automatically with EKS cluster creation
- ✅ Uses Terraform to manage ArgoCD lifecycle
- ✅ Configures initial namespace and AppProject
- ✅ Sets up LoadBalancer for easy access (dev) or port-forward
- ✅ Ready for GitOps repository integration

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      EKS Cluster                        │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          argocd namespace                        │  │
│  │                                                  │  │
│  │  ┌────────────────┐  ┌────────────────┐        │  │
│  │  │ argocd-server  │  │ argocd-repo-   │        │  │
│  │  │                │  │    server      │        │  │
│  │  └────────────────┘  └────────────────┘        │  │
│  │                                                  │  │
│  │  ┌────────────────┐  ┌────────────────┐        │  │
│  │  │ argocd-        │  │ redis          │        │  │
│  │  │ controller     │  │                │        │  │
│  │  └────────────────┘  └────────────────┘        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Your Application Namespaces             │  │
│  │                                                  │  │
│  │     Managed by ArgoCD Applications              │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
                         │ Syncs from
                         ▼
              ┌─────────────────────┐
              │  GitOps Repository  │
              │                     │
              │  - applications/    │
              │  - infrastructure/  │
              │  - clusters/        │
              └─────────────────────┘
```

## Prerequisites

- ✅ EKS cluster running (created by Terraform)
- ✅ `kubectl` configured to access cluster
- ✅ `aws` CLI configured
- ✅ Terraform >= 1.0
- ✅ Git repository for GitOps (to be created)

## Installation

ArgoCD is automatically installed when you apply the compute Terraform configuration:

```bash
cd live/dev/eu-west-1/compute
terraform init
terraform plan
terraform apply
```

This will:
1. Create EKS cluster
2. Install ArgoCD in `argocd` namespace
3. Configure initial AppProject
4. Set up LoadBalancer service (or use port-forward)

**Installation time:** ~5-10 minutes

## Accessing ArgoCD

After Terraform apply completes, you'll see outputs with access instructions.

### Step 1: Configure kubectl

```bash
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev
```

### Step 2: Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

**Username:** `admin`  
**Password:** (output from above command)

> ⚠️ **Important:** Change this password after first login!

### Step 3: Access ArgoCD UI

**Option A: LoadBalancer (Default for Dev)**

```bash
# Get the LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Access via browser
# http://<EXTERNAL-IP>
```

**Option B: Port Forward (Recommended)**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open: `https://localhost:8080`

> Note: You'll get a certificate warning - this is expected for local access.

### Step 4: Login and Change Password

1. Navigate to ArgoCD UI
2. Login with `admin` and the password from Step 2
3. Go to **User Info** → **Update Password**
4. Set a new secure password

## Setting Up GitOps Repository

### Recommended Repository Structure

Create a separate Git repository for your applications:

```
gitops-repo/
├── README.md
├── apps/
│   ├── dev/
│   │   ├── backend/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── kustomization.yaml
│   │   └── frontend/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── kustomization.yaml
│   └── prod/
│       └── ...
├── infrastructure/
│   ├── ingress-nginx/
│   ├── cert-manager/
│   └── metrics-server/
└── argocd/
    ├── projects/
    │   └── default-project.yaml
    └── applications/
        ├── app-of-apps.yaml
        ├── backend-app.yaml
        └── frontend-app.yaml
```

### Adding Your Repository to ArgoCD

**Option 1: Using ArgoCD CLI**

```bash
# Install ArgoCD CLI
brew install argocd  # macOS
# or download from https://github.com/argoproj/argo-cd/releases

# Login
argocd login <ARGOCD_SERVER> --username admin --password <your-password>

# Add repository (public)
argocd repo add https://github.com/your-org/gitops-repo.git

# Add repository (private with HTTPS)
argocd repo add https://github.com/your-org/gitops-repo.git \
  --username <github-username> \
  --password <github-token>

# Add repository (private with SSH)
argocd repo add git@github.com:your-org/gitops-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

**Option 2: Using Kubernetes Manifest**

Create a file `gitops-repo-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitops-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/your-org/gitops-repo.git
  username: <github-username>
  password: <github-token>
```

Apply it:
```bash
kubectl apply -f gitops-repo-secret.yaml
```

## App of Apps Pattern

The "App of Apps" pattern allows you to manage multiple ArgoCD Applications with a single root Application.

### Step 1: Create App of Apps Application

Create `argocd/app-of-apps.yaml` in your GitOps repo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main
    path: argocd/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 2: Create Child Applications

Create `argocd/applications/backend-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main
    path: apps/dev/backend
  destination:
    server: https://kubernetes.default.svc
    namespace: backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 3: Bootstrap the App of Apps

```bash
kubectl apply -f argocd/app-of-apps.yaml
```

Now ArgoCD will:
1. Sync the app-of-apps Application
2. Discover all Applications in `argocd/applications/`
3. Automatically create and sync them

## Best Practices

### 1. Use Git Branches for Environments

```
main       → production
develop    → staging
feature/*  → feature environments
```

### 2. Enable Auto-Sync with Caution

```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Force sync when drift detected
```

⚠️ Use `prune: false` in production until confident!

### 3. Use Projects for Multi-Tenancy

Create separate AppProjects for teams:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a
  namespace: argocd
spec:
  sourceRepos:
    - https://github.com/your-org/gitops-repo.git
  destinations:
    - namespace: 'team-a-*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
```

### 4. Use Kustomize for Environment Overlays

```
apps/backend/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

### 5. Monitor ArgoCD Health

```bash
# Check ArgoCD components
kubectl get pods -n argocd

# Check Application status
kubectl get applications -n argocd

# View Application details
argocd app get <app-name>
```

### 6. Enable Notifications

Configure notifications for sync events (Slack, email, etc.)

### 7. Backup ArgoCD Configuration

```bash
# Export all Applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Export all AppProjects
kubectl get appprojects -n argocd -o yaml > argocd-projects-backup.yaml
```

## Troubleshooting

### ArgoCD Pods Not Starting

```bash
# Check pod status
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-application-controller
```

### Application Sync Failing

```bash
# Check Application status
argocd app get <app-name>

# View sync errors
argocd app sync <app-name> --dry-run

# Force sync
argocd app sync <app-name> --force
```

### Repository Connection Issues

```bash
# List repositories
argocd repo list

# Test connection
argocd repo get https://github.com/your-org/gitops-repo.git
```

### Can't Access ArgoCD UI

```bash
# Check service status
kubectl get svc argocd-server -n argocd

# Check if pods are running
kubectl get pods -n argocd

# Port-forward as fallback
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Reset Admin Password

```bash
# Delete the initial admin secret
kubectl delete secret argocd-initial-admin-secret -n argocd

# Get new password (ArgoCD will regenerate it)
# Restart argocd-server pod
kubectl rollout restart deployment argocd-server -n argocd

# Wait and get new password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Next Steps

1. ✅ Access ArgoCD UI and change admin password
2. ✅ Create a GitOps repository with your applications
3. ✅ Add your repository to ArgoCD
4. ✅ Create your first Application
5. ✅ Set up App of Apps pattern
6. ✅ Configure RBAC and SSO (optional)
7. ✅ Enable notifications (optional)
8. ✅ Deploy your applications!

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kustomize Documentation](https://kustomize.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

## Support

For issues:
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`
- ArgoCD GitHub: https://github.com/argoproj/argo-cd/issues
- ArgoCD Slack: https://argoproj.github.io/community/join-slack

---

**Happy GitOps! 🚀**
