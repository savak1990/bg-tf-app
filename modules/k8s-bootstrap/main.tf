data "aws_region" "current" {}

# IAM Trust policy for a Role associated with service account via pod identity
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
