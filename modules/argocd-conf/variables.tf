variable "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "project_name" {
  description = "Name of the ArgoCD AppProject"
  type        = string
  default     = "default-project"
}

variable "project_description" {
  description = "Description of the ArgoCD AppProject"
  type        = string
  default     = "Default project for applications"
}

variable "source_repos" {
  description = "List of source repositories allowed for the project"
  type        = list(string)
  default     = ["*"]
}

variable "destinations" {
  description = "List of destination clusters/namespaces for the project"
  type = list(object({
    namespace = string
    server    = string
  }))
  default = [
    {
      namespace = "*"
      server    = "https://kubernetes.default.svc"
    }
  ]
}

variable "cluster_resource_whitelist" {
  description = "Cluster-scoped resources allowed for the project"
  type = list(object({
    group = string
    kind  = string
  }))
  default = [
    {
      group = "*"
      kind  = "*"
    }
  ]
}

variable "namespace_resource_whitelist" {
  description = "Namespace-scoped resources allowed for the project"
  type = list(object({
    group = string
    kind  = string
  }))
  default = [
    {
      group = "*"
      kind  = "*"
    }
  ]
}
