data "aws_region" "current" {}

# EKS Pod Identity Agent (required for Pod Identity)
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.3.9-eksbuild.3"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Metrics Server add-on
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = var.cluster_name
  addon_name                  = "metrics-server"
  addon_version               = "v0.8.0-eksbuild.2"
  resolve_conflicts_on_update = "OVERWRITE"
}

# EBS CSI as an EKS managed add-on
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.51.1-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_pod_identity_association.ebs_csi
  ]
}

# Wait for EBS CSI driver to be fully ready before creating storage class
# This ensures the provisioner is available
resource "time_sleep" "wait_for_ebs_csi" {
  create_duration = "20s"

  depends_on = [aws_eks_addon.ebs_csi]
}

# Create EBS GP3 storage class
resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.amazonaws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }

  depends_on = [time_sleep.wait_for_ebs_csi]
}

# CloudWatch Observability Addon
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = var.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = "v4.5.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_pod_identity_association.cloudwatch_observability
  ]
}

# Explicit Pod Identity Association for CloudWatch Observability
resource "aws_eks_pod_identity_association" "cloudwatch_observability" {
  cluster_name    = var.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cw_agent_role.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.cw_agent_policy
  ]
}

# IAM Trust policy for a Role associated with EBS CSI controller service account via pod identity
data "aws_iam_policy_document" "sa_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# IAM Role for EBS CSI controller service account
resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-ebs-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.sa_trust.json
}

# Attach policy to create enencrypted ebs volumes on pvc request
resource "aws_iam_role_policy_attachment" "ebs_csi_managed" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Explicit Pod Identity Association for EBS CSI Driver
# Must be created BEFORE the addon so credentials are available when pods start
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.ebs_csi_managed,
    aws_iam_role_policy_attachment.ebs_csi_driver_additional
  ]
}

# Additional policy for EBS CSI Driver (for encryption, snapshots, etc.)
data "aws_iam_policy_document" "ebs_csi_driver_additional" {
  statement {
    sid    = "EC2DescribeReadOnly"
    effect = "Allow"

    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeAvailabilityZones",
    ]

    # Many EC2 Describe APIs require "*" as the resource; keep if unavoidable
    resources = ["*"]
  }

  statement {
    sid    = "KMSEncryptDecryptForEBS"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]

    # Prefer providing concrete key ARNs via var.kms_key_arns; fall back to "*" if not set
    resources = length(var.kms_key_arns) > 0 ? var.kms_key_arns : ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ebs_csi_driver_additional" {
  name        = "${var.cluster_name}-ebs-csi-driver-additional"
  description = "Additional permissions for EBS CSI Driver"
  policy      = data.aws_iam_policy_document.ebs_csi_driver_additional.json
}

# Attach the additional policy to the EBS CSI role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_additional" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = aws_iam_policy.ebs_csi_driver_additional.arn
}

# IAM Role for service account responsible for CloudWatch Agent
resource "aws_iam_role" "cw_agent_role" {
  name               = "${var.cluster_name}-cloudwatch-agent-role"
  assume_role_policy = data.aws_iam_policy_document.sa_trust.json
}

# Policy that allows to upload logs, metrics, etc
resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
