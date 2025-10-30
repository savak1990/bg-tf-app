# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      name = "argocd"
    }
  }
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.0.5"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Core ArgoCD configuration
  values = [
    yamlencode({
      global = {
        domain = "argocd.local"
      }

      # Controller configuration
      controller = {
        replicas = 1
      }

      # Server configuration
      server = {
        replicas = 1

        service = {
          type = "LoadBalancer"

          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb-ip"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            loadBalancerClass                                     = "service.k8s.aws/nlb"
          }
        }

        # Enable insecure mode for local development (disable TLS)
        # Change this in production
        extraArgs = [
          "--insecure"
        ]
      }

      # Repo server configuration
      repoServer = {
        replicas = 1
      }

      # Redis configuration
      redis = {
        enabled = true
      }

      # ApplicationSet controller
      applicationSet = {
        enabled = true
      }

      # Notifications controller
      notifications = {
        enabled = true
      }

      # Dex (SSO) - disabled by default
      dex = {
        enabled = false
      }

      # Configure RBAC
      configs = {
        # Default to admin for initial setup
        params = {
          "server.insecure" = true
        }
      }
    }),
  ]

  # Wait for all resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [
    kubernetes_namespace.argocd,
    aws_eks_addon.external_dns,
    aws_eks_addon.metrics_server
  ]
}
