# Outputs for ArgoCD Configuration
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.k8s_argocd_config.namespace
}

output "repository_secret_name" {
  description = "Name of the repository secret"
  value       = module.k8s_argocd_config.repository_secret_name
}

output "argocd_projects" {
  description = "Names of created Argo CD projects"
  value       = module.k8s_argocd_config.argocd_projects
}

output "app_of_apps_names" {
  description = "Names of the App-of-Apps applications"
  value       = module.k8s_argocd_config.app_of_apps_names
}
