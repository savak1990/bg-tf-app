variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64 encoded)"
  type        = string
  sensitive   = true
}

variable "cluster_auth_token" {
  description = "EKS cluster authentication token"
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "projects" {
  description = "List of projects and root apps that will be created"
  type = list(object({
    name           = string
    namespace      = string
    repo_url       = string
    repo_apps_path = string
    revision       = string
  }))
}
