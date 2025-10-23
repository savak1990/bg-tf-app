# Outputs for Compute (EKS) Environment
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "node_group_id" {
  description = "EKS node group id"
  value       = module.eks.node_group_id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = module.eks.node_group_arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.eks.node_group_status
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS (for IRSA)"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_url
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${local.aws_region} --name ${local.cluster_name}"
}

# EBS CSI Driver IAM Role
output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver (use this in Helm values)"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_driver_role_name" {
  description = "IAM role name for EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_driver.name
}
