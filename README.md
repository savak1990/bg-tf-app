# BoardGameShop Terraform Infrastructure

This repository contains the Terraform/Terragrunt infrastructure as code for the BoardGameShop project, including VPC networking, EKS clusters, and supporting AWS resources.

## 📁 Project Structure

```
.
├── live/                          # Environment-specific configurations
│   ├── global/                    # Shared/global resources
│   │   ├── networking/            # VPC, subnets, routing
│   │   │   ├── eu-west-1/
│   │   │   └── us-west-2/
│   │   ├── iam/                   # IAM roles and policies
│   │   ├── certificates/          # ACM certificates
│   │   └── dns/                   # Route53 hosted zones
│   ├── dev/                       # Development environment
│   │   └── eu-west-1/
│   ├── staging/                   # Staging environment
│   │   └── eu-west-1/
│   └── prod/                      # Production environment
│       ├── eu-west-1/
│       └── us-west-2/
├── modules/                       # Reusable Terraform modules
│   ├── vpc/                       # VPC module (EKS-ready)
│   └── eks/                       # EKS cluster module
└── shared/                        # Shared configurations
    ├── backend/                   # Remote state backend setup
    └── variables/                 # Common variable definitions
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (optional but recommended)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions

### Initial Setup

1. **Configure AWS credentials:**
   ```bash
   aws configure
   # Or use AWS SSO:
   aws sso login --profile your-profile
   ```

2. **Set up remote state backend (one-time setup):**
   ```bash
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
- Public subnets (for load balancers)
- Private subnets (for EKS worker nodes)
- Internet Gateway
- NAT Gateways (one per AZ for HA)
- Route tables
- VPC endpoints (S3, ECR) for cost optimization
- Proper Kubernetes tags for EKS integration

**Usage:**
```hcl
module "vpc" {
  source = "../../../modules/vpc"
  
  vpc_name             = "my-vpc"
  vpc_cidr             = "10.0.0.0/16"
  aws_region           = "eu-west-1"
  cluster_name         = "my-eks-cluster"
  public_subnet_count  = 2
  private_subnet_count = 2
  enable_nat_gateway   = true
  enable_vpc_endpoints = true
  common_tags          = local.common_tags
}
```

### EKS Module (Coming Soon)

Located in `modules/eks/`, this module will create:
- EKS cluster
- Managed node groups
- IRSA (IAM Roles for Service Accounts)
- Security groups
- Cluster add-ons

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