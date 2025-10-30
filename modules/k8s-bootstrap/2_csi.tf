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

# Create EBS GP3 storage class
resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type = "gp3"

    # iops       = "3000"
    # throughput = "125"
    # encrypted  = "true"

    tagSpecification_1 = "Name={{ .PVCNamespace }}/{{ .PVCName }}"
    tagSpecification_2 = "app=myapp"
    tagSpecification_3 = "pv={{ .PVName }}"
  }

  depends_on = [aws_eks_addon.ebs_csi]
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
