# Terraform DevOps Engineering: Complete Hands-On Handbook

A comprehensive, production-grade guide covering the complete Terraform infrastructure-as-code lifecycle, AWS authentication, remote state locking, reusable modular architecture, variables hierarchy, safe changes, state drift management, and CI/CD pipelines.

---

## Table of Contents
1. [Core Terraform Lifecycle & Mental Model](#1-core-terraform-lifecycle--mental-model)
2. [AWS Authentication & CLI Setup](#2-aws-authentication--cli-setup)
3. [Repository Directory Structure](#3-repository-directory-structure)
4. [Remote State & Concurrency Locking (Bootstrap)](#4-remote-state--concurrency-locking-bootstrap)
5. [Building Reusable Modules (The 3-File Standard)](#5-building-reusable-modules-the-3-file-standard)
6. [Wiring Modules in Environments](#6-wiring-modules-in-environments)
7. [Variables Hierarchy & Evaluation Precedence](#7-variables-hierarchy--evaluation-precedence)
8. [Adding New Services (Standard Procedure)](#8-adding-new-services-standard-procedure)
9. [Safe Resource Modifications & Planning](#9-safe-resource-modifications--planning)
10. [Managing State Drift & Emergency State Commands](#10-managing-state-drift--emergency-state-commands)
11. [Multi-Environment Replication (dev, stg, prod)](#11-multi-environment-replication-dev-stg-prod)
12. [Git Best Practices (.gitignore)](#12-git-best-practices-gitignore)
13. [CI/CD Pipeline Automation](#13-cicd-pipeline-automation)
14. [CLI Command Cheat Sheet](#14-cli-command-cheat-sheet)

---

## 1. Core Terraform Lifecycle & Mental Model

Terraform operates using declarative configuration files to bring target infrastructure into the desired state:

```
[ Your Code (.tf) ] <==== Compares ====> [ terraform.tfstate (AWS Reality) ]
         │
         ▼
[ terraform plan ] (Shows delta: + Add, ~ Change, - Destroy)
         │
         ▼
[ terraform apply ] (Calls AWS APIs and updates remote state file)
```

### The 4 Core Commands:
- `terraform init`: Initializes provider plugins and links module blocks.
- `terraform validate`: Verifies syntax, types, and internal references without contacting cloud APIs.
- `terraform plan`: Generates an execution plan comparing configuration files against the state file.
- `terraform apply`: Provisions or modifies the infrastructure in AWS.

---

## 2. AWS Authentication & CLI Setup

Never hardcode AWS keys inside `.tf` files. Terraform automatically uses credentials stored in `~/.aws/credentials`.

### Step-by-Step Setup:
```powershell
# 1. Verify installed versions
terraform -version
aws --version

# 2. Configure AWS credentials locally
aws configure
# Prompts:
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: us-east-1
# Default output format: json

# 3. Verify active identity and account ID
aws sts get-caller-identity
```

---

## 3. Repository Directory Structure

```
aws-teraform-learning-IaC/
│
├── infra/
│   │
│   ├── bootstrap/               # Run ONCE: Creates S3 State Bucket + DynamoDB Lock Table
│   │   └── main.tf
│   │
│   ├── modules/                 # Reusable Building Blocks (Generic recipes)
│   │   ├── s3/                  # (main.tf, variables.tf, outputs.tf)
│   │   ├── vpc/                 # (main.tf, variables.tf, outputs.tf)
│   │   ├── security-groups/     # (main.tf, variables.tf, outputs.tf)
│   │   ├── ec2/                 # (main.tf, variables.tf, outputs.tf)
│   │   ├── alb/                 # (main.tf, variables.tf, outputs.tf)
│   │   ├── ecr/                 # (main.tf, variables.tf, outputs.tf)
│   │   ├── iam/                 # (main.tf, variables.tf, outputs.tf)
│   │   ├── secrets-manager/     # (main.tf, variables.tf, outputs.tf)
│   │   ├── rds/                 # (main.tf, variables.tf, outputs.tf)
│   │   └── monitoring/          # (main.tf, variables.tf, outputs.tf)
│   │
│   └── environments/            # Environment Assemblies (Passes real parameters)
│       ├── dev/
│       │   ├── provider.tf      # Provider constraints + S3 Backend block
│       │   ├── variables.tf     # Environment variable declarations
│       │   ├── terraform.tfvars # Concrete input values
│       │   ├── main.tf          # Instantiates modules & connects outputs/inputs
│       │   └── outputs.tf       # Exposes endpoints, URLs, and IDs
│       ├── stg/
│       └── prod/
│
├── notes.md                     # Architecture documentation & handbook
└── .gitignore                   # Excludes state files, caches, and secrets
```

---

## 4. Remote State & Concurrency Locking (Bootstrap)

Storing state on a local laptop risk data loss and allows race conditions where two engineers overwrite each other. We use **S3** (encrypted, versioned) + **DynamoDB** (state locking).

### Step 1: Deploy Bootstrap (`infra/bootstrap/main.tf`)
```hcl
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-app-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "devops-app-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

Run once:
```powershell
cd infra/bootstrap
terraform init
terraform apply -auto-approve
```

### Step 2: Connect S3 Backend in Environment (`infra/environments/dev/provider.tf`)
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "devops-app-tfstate-750907156533" # Your unique bucket
    key            = "dev/terraform.tfstate"           # Environment isolation key
    region         = "us-east-1"
    dynamodb_table = "devops-app-terraform-locks"      # Prevents concurrent writes
    encrypt        = true
  }
}
```

Initialize/Migrate:
```powershell
cd infra/environments/dev
terraform init -reconfigure
```

---

## 5. Building Reusable Modules (The 3-File Standard)

Every module inside `infra/modules/<service>` must be completely generic and contain 3 files:

### 1. `variables.tf` (Inputs)
Parameterize all configurable settings:
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags map"
  type        = map(string)
  default     = {}
}
```

### 2. `main.tf` (Resources)
```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}
```

### 3. `outputs.tf` (Exports)
Expose attributes so other modules can consume them:
```hcl
output "bucket_id" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}
```

---

## 6. Wiring Modules in Environments

Inside `infra/environments/dev/main.tf`, call the modules and connect dependencies:

```hcl
# Service 1: Networking
module "vpc" {
  source              = "../../modules/vpc"
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
}

# Service 2: Security Groups (Dependency Handshake from VPC)
module "security_groups" {
  source       = "../../modules/security-groups"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id  # <--- Fed directly from VPC module output
}

# Service 3: Compute (Dependency Handshake from VPC + Security Groups)
module "ec2_server" {
  source                 = "../../modules/ec2"
  project_name           = var.project_name
  environment            = var.environment
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.ec2_security_group_id]
}
```

---

## 7. Variables Hierarchy & Evaluation Precedence

Terraform loads variables according to a strict priority hierarchy (lowest to highest):

1. **Module `variables.tf` defaults**: `default = "t3.micro"`
2. **Environment `variables.tf` defaults**: `default = "dev"`
3. **`terraform.tfvars` / `terraform.tfvars.json`**: Auto-loaded file in the working directory.
4. **`*.auto.tfvars`**: Evaluated in lexical order.
5. **Command-line flags (`-var` or `-var-file`)**: Highest priority (overrides everything).
   ```powershell
   terraform plan -var="environment=staging"
   ```

---

## 8. Adding New Services (Standard Procedure)

To add any new AWS service (e.g., RDS Database):

1. **Step 1**: Create `infra/modules/rds/` containing `variables.tf`, `main.tf`, `outputs.tf`.
2. **Step 2**: Accept needed dependencies as inputs (`vpc_id`, `subnet_ids`, `db_security_group_id`).
3. **Step 3**: Export important connection data (`db_endpoint`, `db_name`, `db_port`).
4. **Step 4**: Open `infra/environments/dev/main.tf` and declare:
   ```hcl
   module "rds" {
     source               = "../../modules/rds"
     vpc_id               = module.vpc.vpc_id
     subnet_ids           = module.vpc.private_subnet_ids
     db_security_group_id = module.security_groups.db_security_group_id
   }
   ```
5. **Step 5**: Execute lifecycle commands:
   ```powershell
   terraform init       # Registers the new module
   terraform validate   # Syntax check
   terraform plan       # Verifies only new resources will be created
   terraform apply      # Provisions to AWS
   ```

---

## 9. Safe Resource Modifications & Planning

Changes fall into 3 risk levels:
- `~ update in-place`: Zero-downtime modification (e.g. adding tags, security group rule).
- `-/+ destroy and then create replacement`: **Destructive replacement** (e.g. changing AMI, VPC CIDR, or AZ).
- `- destroy`: Resource deletion.

### Recommended Production Planning Workflow:
```powershell
# 1. Output plan to a binary file
terraform plan -out=tfplan.binary

# 2. Apply ONLY the exact approved plan
terraform apply tfplan.binary

# 3. Clean up the binary file
Remove-Item tfplan.binary
```

---

## 10. Managing State Drift & Emergency State Commands

When external changes occur directly in the AWS Console, the state file becomes out of sync (**drift**).

| Command | Description |
| :--- | :--- |
| `terraform state list` | Lists all resources tracked in the state file. |
| `terraform state show <address>` | Displays complete JSON attributes of a tracked resource. |
| `terraform plan -refresh-only` | Detects drift made manually in the AWS Console. |
| `terraform apply -refresh-only` | Saves console changes into the state without altering AWS resources. |
| `terraform state rm <address>` | Removes a resource from state **without deleting it in AWS**. |
| `terraform import <address> <id>` | Imports an existing AWS resource into Terraform management. |
| `terraform state mv <src> <dst>` | Renames/moves a resource in code without destroying it. |

---

## 11. Multi-Environment Replication (`dev`, `stg`, `prod`)

Because modules are isolated in `infra/modules/`, new environments are created with zero code duplication:

1. Copy `infra/environments/dev` to `infra/environments/prod`.
2. In `infra/environments/prod/provider.tf`, set:
   ```hcl
   backend "s3" {
     bucket = "devops-app-tfstate-750907156533"
     key    = "prod/terraform.tfstate" # Separate state per environment
     ...
   }
   ```
3. Update `infra/environments/prod/terraform.tfvars` with production sizes (e.g. multi-AZ, larger instances).
4. Run:
   ```powershell
   cd infra/environments/prod
   terraform init
   terraform apply
   ```

---

## 12. Git Best Practices (`.gitignore`)

Never commit state files, credentials, or provider caches to version control.

Your root `.gitignore`:
```gitignore
# Terraform local state files (state lives in S3)
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.binary

# CLI & Provider caches
.terraform/
.terraform.lock.hcl

# Secret files
*.tfvars
*.tfvars.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Crash logs
crash.log
crash.*.log
```

---

## 13. CI/CD Pipeline Automation

In standard teams, Terraform is driven by Git pull requests rather than personal workstations.

### Example GitHub Actions Workflow (`.github/workflows/terraform.yml`):
```yaml
name: "Terraform CI/CD"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: infra/environments/dev

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Format check
        run: terraform fmt -check -recursive

      - name: Init
        run: terraform init

      - name: Validate
        run: terraform validate

      - name: Plan
        run: terraform plan

      - name: Apply (Main Branch Only)
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
```

---

## 14. CLI Command Cheat Sheet

```powershell
# Directory formatting & validation
terraform fmt -recursive
terraform validate

# Initialization & reconfiguring backend
terraform init
terraform init -reconfigure
terraform init -migrate-state

# Planning & deployment
terraform plan
terraform plan -out=tfplan.binary
terraform apply tfplan.binary
terraform apply -auto-approve

# Targeted execution (for quick debugging/single-resource action)
terraform plan -target=module.ec2_server
terraform apply -target=module.ec2_server

# State inspection & outputs
terraform state list
terraform state show module.ec2_server.aws_instance.this
terraform output
terraform output ec2_web_url

# Teardown & cost prevention
terraform destroy
terraform destroy -auto-approve
```

