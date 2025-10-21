# BoardGameShop Terraform Infrastructure

This repository contains Terraform infrastructure as code for the BoardGameShop project, including VPC networking and supporting AWS resources.

## 📁 Project Structure

```
.
├── Makefile                       # Build automation commands
├── live/                          # Environment-specific configurations
│   └── dev/                       # Development environment
│       └── eu-west-1/             # EU West 1 region
│           ├── networking/        # VPC networking
│           │   ├── main.tf        # Main configuration
│           │   ├── provider.tf    # Provider configuration
│           │   └── outputs.tf     # Output values
│           └── compute/           # EKS cluster
│               ├── main.tf        # Main configuration
│               ├── provider.tf    # Provider configuration
│               └── outputs.tf     # Output values
└── modules/                       # Reusable Terraform modules
    ├── vpc/                       # VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/                       # EKS module
        ├── README.md
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions
- Make (for using Makefile commands)

### Initial Setup

1. **Configure AWS credentials:**
   ```bash
   aws configure
   # Or use AWS SSO:
   aws sso login --profile your-profile
   ```

2. **Set up remote state backend (one-time setup):**
   
   Create S3 bucket and DynamoDB table for state management:
   ```bash
   # Create S3 bucket
   aws s3 mb s3://bg-tf-state-vk --region eu-west-1
   aws s3api put-bucket-versioning \
     --bucket bg-tf-state-vk \
     --versioning-configuration Status=Enabled
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name bg-tf-state-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
     --region eu-west-1
   ```
   cd shared/backend
   terraform init
   terraform apply
   # Note the S3 bucket and DynamoDB table names from outputs
   ```

3. **Update backend configuration:**
   - Edit the backend configuration in each `main.tf` file
   - Replace `your-terraform-state-bucket` with the actual bucket name
   - Uncomment the backend block

### Deployment Order

Infrastructure should be deployed in the following order to respect dependencies:

#### 1. Global Infrastructure

```bash
# Deploy networking (VPC, subnets, routing)
cd live/global/networking/eu-west-1
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply

# Repeat for other regions as needed
cd ../us-west-2
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

#### 2. IAM Resources (if applicable)
```bash
cd live/global/iam/eu-west-1
# Similar steps as above
```

#### 3. Environment-Specific Resources

```bash
# Development environment
cd live/dev/eu-west-1
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply

# Production environment
cd live/prod/eu-west-1
# Similar steps
```

## 📝 Configuration

### Variable Files

Each environment has a `terraform.tfvars.example` file showing required variables:

1. **Copy the example file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your values:**
   ```hcl
   project_name = "boardgameshop"
   aws_region   = "eu-west-1"
   vpc_cidr     = "10.0.0.0/16"
   # ... other variables
   ```

3. **Never commit `terraform.tfvars`** - it's in `.gitignore` for security

### Remote State

Environments reference shared resources via `terraform_remote_state`:

```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "global/networking/eu-west-1/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Use outputs:
vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
```

## 🏗️ Modules

### VPC Module

Located in `modules/vpc/`, this module creates an EKS-ready VPC with:

- VPC with configurable CIDR
- Public subnets across multiple availability zones
- Internet Gateway
- Route tables with proper routing
- Proper tags for resource management

**Usage:**
```hcl
module "vpc" {
  source = "../../../../modules/vpc"
  
  vpc_name            = "my-vpc"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_count = 2
}
```

See [modules/vpc/README.md](modules/vpc/README.md) for detailed documentation.

### EKS Module

Located in `modules/eks/`, this module creates a production-ready EKS cluster with:

- EKS control plane with configurable Kubernetes version
- Managed node group with auto-scaling
- IAM roles and policies for cluster and nodes
- Security groups with proper ingress/egress rules
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Comprehensive control plane logging
- Support for public and private API endpoints

**Features:**
- Configurable instance types (default: m5.large - 2 vCPU, 8 GB RAM)
- Configurable node count (min, max, desired)
- Best practices security configuration
- Full integration with VPC module

**Usage:**
```hcl
module "eks" {
  source = "../../../../modules/eks"
  
  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.31"
  
  vpc_id     = data.terraform_remote_state.networking.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.networking.outputs.public_subnet_ids

  instance_type = "m5.large"
  desired_size  = 3
  min_size      = 2
  max_size      = 5
}
```

See [modules/eks/README.md](modules/eks/README.md) for detailed documentation.

## 🚀 Deployment Example

Here's how to deploy the complete infrastructure:

### 1. Deploy VPC (Networking)

```bash
cd live/dev/eu-west-1/networking
terraform init
terraform plan
terraform apply
```

### 2. Deploy EKS Cluster (Compute)

```bash
cd ../compute
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

After EKS deployment completes, configure kubectl:

```bash
aws eks update-kubeconfig --region eu-west-1 --name bg-eks-dev
kubectl get nodes
```

## 🔒 Security Best Practices

1. **Never commit sensitive data:**
   - `*.tfvars` files are gitignored
   - Use AWS Secrets Manager or Parameter Store for secrets
   - Use environment variables for CI/CD

2. **Use remote state with locking:**
   - S3 backend with encryption enabled
   - DynamoDB table for state locking
   - Versioning enabled on state bucket

3. **Enable MFA for production:**
   - Require MFA for destructive operations
   - Use separate AWS accounts for environments

4. **Review plans before applying:**
   ```bash
   terraform plan -out=plan.out
   # Review the plan carefully
   terraform apply plan.out
   ```

## 🛠️ Common Operations

### Initialize a new environment
```bash
cd live/[environment]/[region]
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
```

### View current state
```bash
terraform show
terraform state list
```

### Update infrastructure
```bash
terraform plan
terraform apply
```

### Destroy resources (use with caution!)
```bash
terraform plan -destroy
terraform destroy
```

### Format code
```bash
terraform fmt -recursive
```

### Validate configuration
```bash
terraform validate
```

### View outputs
```bash
terraform output
terraform output vpc_id
```

## 🌍 Multi-Region Deployment

To deploy in multiple regions:

1. Create region-specific directories under each environment
2. Copy and customize `terraform.tfvars` for each region
3. Ensure backend keys are unique per region
4. Deploy global resources once per region
5. Reference the correct remote state for each region

Example:
```
live/global/networking/
  ├── eu-west-1/     # Primary region
  └── us-west-2/     # Secondary region

live/prod/
  ├── eu-west-1/     # References eu-west-1 networking
  └── us-west-2/     # References us-west-2 networking
```

## 📊 State Management

### Local State (Development)
For initial development, local state is used:
```hcl
# No backend block = local state
```

### Remote State (Production)
For team collaboration and production:
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "path/to/terraform.tfstate"
  region         = "eu-west-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### Migrating from Local to Remote State
```bash
# 1. Uncomment backend configuration in main.tf
# 2. Run init with migration
terraform init -migrate-state
```

## 🐛 Troubleshooting

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Refresh State
```bash
terraform refresh
```

### Import Existing Resources
```bash
terraform import module.vpc.aws_vpc.main vpc-xxxxx
```

### Debug Mode
```bash
export TF_LOG=DEBUG
terraform plan
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 👥 Contributing

1. Create a feature branch
2. Make changes and test locally
3. Run `terraform fmt` and `terraform validate`
4. Create a plan output: `terraform plan -out=plan.out`
5. Submit PR with plan output for review

## 📄 License

[Your License Here]

## 📧 Contact

[Your Contact Information]

---

**Note:** Always review Terraform plans carefully before applying changes to production environments.