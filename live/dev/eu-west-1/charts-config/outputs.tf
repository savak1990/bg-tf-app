# Outputs for ArgoCD Configuration
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd_config.namespace
}

output "app_of_apps_name" {
  description = "Name of the App-of-Apps application"
  value       = module.argocd_config.app_of_apps_name
}

output "app_of_apps_namespace" {
  description = "Namespace of the App-of-Apps application"
  value       = module.argocd_config.app_of_apps_namespace
}

output "apps_path" {
  description = "Path of applications in gitops repo"
  value       = local.apps_path
}

output "repository_secret_name" {
  description = "Name of the repository secret"
  value       = module.argocd_config.repository_secret_name
}

output "repository_url" {
  description = "Repository URL configured for ArgoCD"
  value       = module.argocd_config.repository_url
}
