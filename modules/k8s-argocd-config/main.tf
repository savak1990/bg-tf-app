locals {
  projects_by_name = { for p in var.projects : p.name => p }
}

# Create repository secret for public GitHub repo (URL only, no credentials)
resource "kubernetes_secret" "repository_secret" {
  for_each = local.projects_by_name

  metadata {
    name      = "${each.key}-repo"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type = "git"
    url  = each.value.repo_url
  }
}

# ArgoCD Project
resource "kubernetes_manifest" "argocd_project" {
  for_each = local.projects_by_name

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = each.key
      namespace = var.namespace
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      description = "Project ${each.key}"

      # Pin to the repo that defines apps for this project
      sourceRepos = [
        each.value.repo_url
      ]

      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]

      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]

      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "app_of_apps" {
  for_each = local.projects_by_name

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${each.key}-apps"
      namespace = var.namespace
      annotations = {
        # Optional: wave 1 so it comes after the AppProject (wave 0)
        "argocd.argoproj.io/sync-wave" = "1"
        # Optional: ensure children are deleted before the parent
        "argocd.argoproj.io/cascade" = "foreground"
      }
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = each.key

      source = {
        repoURL        = each.value.repo_url
        targetRevision = each.value.revision
        path           = each.value.repo_apps_path

        # If your app-of-apps directory only contains Application manifests,
        # you usually don't need recurse = true; keep it if you rely on it.
        directory = {
          recurse = true
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = each.value.namespace
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

  depends_on = [
    kubernetes_secret.repository_secret,
    kubernetes_manifest.argocd_project,
  ]
}
