# Create repository secret for public GitHub repo (URL only, no credentials)
resource "kubernetes_secret" "repository_secret" {
  metadata {
    name      = var.repository_name
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type = "git"
    url  = var.repository_url
  }
}

# Create root App-of-Apps application
resource "kubernetes_manifest" "app_of_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.app_of_apps_name
      namespace = var.namespace
      annotations = {
        "argocd.argoproj.io/cascade" = "foreground"
      }
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default" # Use ArgoCD's built-in default project

      source = {
        repoURL        = var.repository_url
        targetRevision = var.target_revision
        path           = var.apps_path
        directory = {
          recurse = true
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [kubernetes_secret.repository_secret]
}
