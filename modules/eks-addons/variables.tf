variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

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

variable "kms_key_arns" {
  description = "List of KMS key ARNs the EBS CSI Driver shold be allowed to use. Falls back to all keys"
  type        = list(string)
  default     = []
}
