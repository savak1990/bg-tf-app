# ArgoCD Outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd.namespace
}

output "argocd_admin_password_command" {
  description = "Command to retrieve ArgoCD admin password"
  value       = module.argocd.admin_password_command
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = module.argocd.port_forward_command
}

output "argocd_server_service" {
  description = "ArgoCD server service information"
  value = {
    name = module.argocd.argocd_server_service_name
    type = module.argocd.argocd_server_service_type
  }
}
