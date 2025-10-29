output "namespace" {
  description = "ArgoCD namespace"
  value       = var.namespace
}

output "repository_secret_name" {
  description = "Name of the repository secret"
  value       = { for k, v in kubernetes_secret.repository_secret : k => v.metadata[0].name }
}

output "argocd_projects" {
  description = "Names of created Argo CD projects"
  value       = { for k, v in kubernetes_manifest.argocd_project : k => v.manifest.metadata.name }
}

output "app_of_apps_names" {
  description = "Names of the App-of-Apps applications"
  value       = { for k, v in kubernetes_manifest.app_of_apps : k => v.manifest.metadata.name }
}

