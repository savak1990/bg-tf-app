# ArgoCD Outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.k8s_bootstrap.namespace
}

output "argocd_admin_password_command" {
  description = "Command to retrieve ArgoCD admin password"
  value       = module.k8s_bootstrap.admin_password_command
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = module.k8s_bootstrap.port_forward_command
}

output "argocd_server_service" {
  description = "ArgoCD server service information"
  value = {
    name = module.k8s_bootstrap.argocd_server_service_name
    type = module.k8s_bootstrap.argocd_server_service_type
  }
}
