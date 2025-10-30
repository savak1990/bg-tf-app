output "storage_class_name" {
  description = "Name of the created EBS GP3 storage class"
  value       = kubernetes_storage_class.ebs_gp3.metadata[0].name
}

output "ebs_csi_addon_id" {
  description = "EBS CSI addon ID"
  value       = aws_eks_addon.ebs_csi.id
}

output "ebs_csi_addon_arn" {
  description = "EBS CSI addon ARN"
  value       = aws_eks_addon.ebs_csi.arn
}

output "metrics_server_addon_id" {
  description = "Metrics Server addon ID"
  value       = aws_eks_addon.metrics_server.id
}

output "metrics_server_addon_arn" {
  description = "Metrics Server addon ARN"
  value       = aws_eks_addon.metrics_server.arn
}

output "pod_identity_agent_addon_id" {
  description = "EKS Pod Identity Agent addon ID"
  value       = aws_eks_addon.pod_identity_agent.id
}

output "pod_identity_agent_addon_arn" {
  description = "EKS Pod Identity Agent addon ARN"
  value       = aws_eks_addon.pod_identity_agent.arn
}

output "cloudwatch_observability_addon_id" {
  description = "CloudWatch Observability addon ID"
  value       = aws_eks_addon.cloudwatch_observability.id
}

output "cloudwatch_observability_addon_arn" {
  description = "CloudWatch Observability addon ARN"
  value       = aws_eks_addon.cloudwatch_observability.arn
}

output "ebs_csi_iam_role_arn" {
  description = "ARN of the IAM role for EBS CSI driver"
  value       = aws_iam_role.ebs_csi.arn
}

output "cloudwatch_agent_iam_role_arn" {
  description = "ARN of the IAM role for CloudWatch agent"
  value       = aws_iam_role.cw_agent_role.arn
}
