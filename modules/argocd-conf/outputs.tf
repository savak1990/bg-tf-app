output "argocd_project_name" {
  description = "Name of the ArgoCD AppProject"
  value       = kubernetes_manifest.argocd_project.manifest.metadata.name
}

output "argocd_project_namespace" {
  description = "Namespace of the ArgoCD AppProject"
  value       = kubernetes_manifest.argocd_project.manifest.metadata.namespace
}
