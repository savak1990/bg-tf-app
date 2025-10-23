variable "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "repository_url" {
  description = "GitHub repository URL for ArgoCD (public repo, no credentials needed)"
  type        = string
}

variable "repository_name" {
  description = "Name for the repository secret"
  type        = string
  default     = "bg-app-repo"
}

variable "app_of_apps_name" {
  description = "Name for the root App-of-Apps application"
  type        = string
  default     = "bg-app-of-apps"
}

variable "apps_path" {
  description = "Path within the repository containing application manifests"
  type        = string
  default     = "applications"
}

variable "target_revision" {
  description = "Git revision to sync from (branch, tag, or commit)"
  type        = string
  default     = "HEAD"
}
