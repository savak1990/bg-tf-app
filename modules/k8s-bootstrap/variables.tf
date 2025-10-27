variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data for EKS cluster"
  type        = string
  sensitive   = true
}

variable "cluster_auth_token" {
  description = "EKS cluster authentication token"
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = "7.7.11" # ArgoCD 2.13.2
}

variable "enable_ha" {
  description = "Enable high availability mode for ArgoCD"
  type        = bool
  default     = false
}

variable "admin_password_secret_name" {
  description = "Name of the Kubernetes secret containing admin password (optional, will be auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "ingress_enabled" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Hostname for ArgoCD ingress"
  type        = string
  default     = ""
}

variable "helm_values" {
  description = "Additional Helm values to pass to ArgoCD chart"
  type        = any
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (optional)"
  type        = string
  default     = ""
}
