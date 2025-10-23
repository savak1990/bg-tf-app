# Outputs for ArgoCD Configuration
output "argocd_project_name" {
  description = "Name of the default ArgoCD project"
  value       = module.argocd_config.argocd_project_name
}

output "argocd_project_namespace" {
  description = "Namespace of the ArgoCD project"
  value       = module.argocd_config.argocd_project_namespace
}
