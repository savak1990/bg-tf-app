# Create initial AppProject for applications
resource "kubernetes_manifest" "argocd_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.project_name
      namespace = var.namespace
    }
    spec = {
      description = var.project_description

      sourceRepos = var.source_repos

      destinations = [
        for dest in var.destinations : {
          namespace = dest.namespace
          server    = dest.server
        }
      ]

      clusterResourceWhitelist = [
        for resource in var.cluster_resource_whitelist : {
          group = resource.group
          kind  = resource.kind
        }
      ]

      namespaceResourceWhitelist = [
        for resource in var.namespace_resource_whitelist : {
          group = resource.group
          kind  = resource.kind
        }
      ]
    }
  }
}
