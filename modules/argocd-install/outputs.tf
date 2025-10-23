output "namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "Name of the ArgoCD server service"
  value       = "argocd-server"
}

output "argocd_server_service_type" {
  description = "Type of the ArgoCD server service"
  value       = var.ingress_enabled ? "ClusterIP" : "LoadBalancer"
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.argocd.name
}

output "helm_release_version" {
  description = "Version of the Helm release"
  value       = helm_release.argocd.version
}

output "admin_password_command" {
  description = "Command to retrieve the initial admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443"
}
