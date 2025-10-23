locals {
  # Hardcoded project and environment
  project     = "bg"
  environment = "dev"
  aws_region  = "eu-west-1"

  # Common tags
  common_tags = {
    Project     = local.project
    Environment = local.environment
    Region      = local.aws_region
    ManagedBy   = "terraform"
    Repository  = "bg-tf-app"
  }

  # EKS configuration
  cluster_name  = "${local.project}-eks-${local.environment}"
  instance_type = "m5.large" # 2 vCPU, 8 GB RAM
  desired_size  = 3
  min_size      = 1
  max_size      = 5
}

# Data source to get networking outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "bg-tf-state-vk"
    key    = "dev/eu-west-1/networking/terraform.tfstate"
    region = "eu-west-1"
  }
}

# EKS Cluster Module
module "eks" {
  source = "../../../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = "1.31"

  vpc_id     = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.public_subnet_ids

  # Node group configuration
  instance_type = local.instance_type
  desired_size  = local.desired_size
  min_size      = local.min_size
  max_size      = local.max_size
  disk_size     = 20

  # API endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  # Enable comprehensive cluster logging
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.common_tags
}

# ============================================
# EBS CSI Driver IAM Role (IRSA)
# ============================================

# Get AWS account ID and OIDC provider details
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${local.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-ebs-csi-driver-role"
    }
  )
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Additional policy for EBS CSI Driver (for encryption, snapshots, etc.)
resource "aws_iam_policy" "ebs_csi_driver_additional" {
  name        = "${local.cluster_name}-ebs-csi-driver-additional"
  description = "Additional permissions for EBS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${local.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_additional" {
  policy_arn = aws_iam_policy.ebs_csi_driver_additional.arn
  role       = aws_iam_role.ebs_csi_driver.name
}
