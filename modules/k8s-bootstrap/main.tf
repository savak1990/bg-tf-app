# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      name = var.namespace
    }
  }
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Core ArgoCD configuration
  values = [
    yamlencode({
      global = {
        domain = var.ingress_host != "" ? var.ingress_host : "argocd.local"
      }

      # Controller configuration
      controller = {
        replicas = var.enable_ha ? 2 : 1
      }

      # Server configuration
      server = {
        replicas = var.enable_ha ? 2 : 1

        service = {
          type = var.ingress_enabled ? "ClusterIP" : "LoadBalancer"

          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb-ip"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            loadBalancerClass                                     = "service.k8s.aws/nlb"
          }
        }

        ingress = {
          enabled = var.ingress_enabled
          hosts   = var.ingress_host != "" ? [var.ingress_host] : []
        }

        # Enable insecure mode for local development (disable TLS)
        # Change this in production
        extraArgs = [
          "--insecure"
        ]
      }

      # Repo server configuration
      repoServer = {
        replicas = var.enable_ha ? 2 : 1
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
    # Allow merging with custom values
    var.helm_values != {} ? yamlencode(var.helm_values) : ""
  ]

  # Wait for all resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [
    kubernetes_namespace.argocd
  ]
}
