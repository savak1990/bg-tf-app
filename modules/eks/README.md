# EKS Module

This Terraform module creates an Amazon EKS (Elastic Kubernetes Service) cluster with a managed node group following AWS best practices.

## Features

- **EKS Cluster**: Creates an EKS cluster with configurable Kubernetes version
- **Managed Node Group**: Deploys EC2 instances as worker nodes with auto-scaling
- **IAM Roles**: Proper IAM roles for cluster and worker nodes with required policies
- **Security Groups**: Dedicated security groups for cluster and nodes with proper ingress/egress rules
- **OIDC Provider**: Enables IAM Roles for Service Accounts (IRSA) for pod-level IAM permissions
- **Control Plane Logging**: Comprehensive logging for audit and troubleshooting
- **Network Configuration**: Supports both public and private API endpoints

## Usage

```hcl
module "eks" {
  source = "../../../../modules/eks"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.31"
  
  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]

  # Node group configuration
  instance_type = "m5.large"
  desired_size  = 3
  min_size      = 2
  max_size      = 5
  disk_size     = 20

  # API endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  # Enable comprehensive cluster logging
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | VPC ID where the cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster and nodes | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.31"` | no |
| instance_type | EC2 instance type for the EKS worker nodes | `string` | `"m5.large"` | no |
| desired_size | Desired number of worker nodes | `number` | `3` | no |
| min_size | Minimum number of worker nodes | `number` | `1` | no |
| max_size | Maximum number of worker nodes | `number` | `5` | no |
| disk_size | Disk size in GB for worker nodes | `number` | `20` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| cluster_log_types | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data (sensitive) |
| cluster_version | The Kubernetes server version for the cluster |
| node_security_group_id | Security group ID attached to the EKS nodes |
| node_group_id | EKS node group id |
| node_group_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| node_group_status | Status of the EKS node group |
| node_iam_role_arn | IAM role ARN for EKS nodes |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| oidc_provider_arn | ARN of the OIDC Provider for EKS |
| oidc_provider_url | URL of the OIDC Provider for EKS |

## Instance Types

Common instance types suitable for EKS nodes:

- **m5.large**: 2 vCPU, 8 GB RAM (default)
- **m5.xlarge**: 4 vCPU, 16 GB RAM
- **m5.2xlarge**: 8 vCPU, 32 GB RAM
- **t3.medium**: 2 vCPU, 4 GB RAM (burstable, cost-effective for dev)
- **t3.large**: 2 vCPU, 8 GB RAM (burstable)

## Best Practices Implemented

1. **IAM Roles**: Separate IAM roles for cluster and nodes with minimal required permissions
2. **Security Groups**: Dedicated security groups with specific ingress/egress rules
3. **OIDC Provider**: Enables IAM Roles for Service Accounts (IRSA) for fine-grained pod permissions
4. **Control Plane Logging**: All log types enabled for comprehensive audit trail
5. **Auto-scaling**: Node group configured with min/max/desired sizes for flexibility
6. **Lifecycle Policies**: Ignores desired_size changes to allow external auto-scaling
7. **Network Isolation**: Supports both public and private API endpoints
8. **Resource Tagging**: All resources properly tagged for cost tracking and management

## Post-Deployment

After the cluster is created, configure kubectl to access it:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

Verify the connection:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 6.0
- TLS Provider ~> 4.0
