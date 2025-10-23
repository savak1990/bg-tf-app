output "repository_secret_name" {
  description = "Name of the repository secret"
  value       = kubernetes_secret.repository_secret.metadata[0].name
}

output "app_of_apps_name" {
  description = "Name of the App-of-Apps application"
  value       = kubernetes_manifest.app_of_apps.manifest.metadata.name
}

output "app_of_apps_namespace" {
  description = "Namespace of the App-of-Apps application"
  value       = kubernetes_manifest.app_of_apps.manifest.metadata.namespace
}

output "repository_url" {
  description = "Repository URL configured for ArgoCD"
  value       = var.repository_url
}

output "namespace" {
  description = "ArgoCD namespace"
  value       = var.namespace
}
