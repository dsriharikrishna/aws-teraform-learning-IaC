# Terraform Practice

A hands-on path for learning Terraform and AWS infrastructure as code. Complete the labs in order, keep each lab in its own folder, and run `terraform destroy` when you finish any lab that creates resources.

## Before you start

- Install Terraform and the AWS CLI.
- On Windows, install Terraform from PowerShell with `winget install --id Hashicorp.Terraform --exact`. Open a new PowerShell window afterward and verify with `terraform -version`.
- Configure AWS credentials locally with `aws configure` or an AWS IAM Identity Center profile. Never put credentials in Terraform files or commit them.
- Use a personal sandbox account, check AWS costs before applying, and destroy cloud resources as soon as you finish.
- Run `terraform fmt` and `terraform validate` before every plan.
- Do not apply a plan until you understand which resources it will create, change, or destroy.

## Labs

### 1. Terraform workflow and local resources

The runnable starter configuration is in `01-local-basics`. It uses the `local` provider to create a text file containing a greeting and the `random` provider to generate a name suffix. From the repository root, run:

```powershell
Set-Location .\01-local-basics
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
Set-Location ..
```

Approve `terraform apply` only after checking the plan. This lab creates a local text file, not AWS resources.

Practice:

- Declare `required_providers` and a Terraform version constraint.
- Define input variables, local values, and outputs.
- Run `terraform init`, `terraform fmt`, `terraform validate`, `terraform plan`, `terraform apply`, and `terraform destroy`.

**Done when:** changing the greeting updates the file, and the output shows the generated file path.

### 2. Variables, types, and validation

Create `02-variables`. Define variables for an application name, environment, and list of tags. Add descriptions, types, defaults where appropriate, and validation rules (for example, restrict environment to `dev`, `test`, or `prod`).

**Done when:** valid inputs produce a plan and an invalid environment is rejected with a useful message.

### 3. Reusable modules

Create a small local module that builds a consistent set of tags and outputs them. Call it from a root module for two sample resources.

Practice module inputs, outputs, relative module sources, and keeping root configuration separate from reusable configuration.

**Done when:** both resources receive the common tags and the module can be called with different names.

### 4. State and configuration changes

Use the local provider to create a resource, inspect the state with `terraform state list` and `terraform state show`, then change a configuration value and review the plan.

Practice state's role, resource addressing, and why state files must not be committed or edited manually.

**Done when:** you can explain the difference between configuration, state, and a plan. Remove generated state and other local artifacts from version control.

### 5. AWS provider and a low-cost resource

Create `05-aws-basics`. Configure the AWS provider using a named local profile or the standard credential chain. Use a uniquely named S3 bucket in a region you choose.

Practice provider configuration, variables, outputs, and reviewing a plan. Enable public-access blocking and default encryption; do not upload sensitive data.

**Done when:** the bucket is private, its name is provided as an output, and `terraform destroy` removes it successfully.

### 6. Network building blocks

In a new lab, define a VPC, one subnet, and the required routing resources. Use variables for the CIDR blocks and tags.

Practice resource references and dependency graphs. Do not add an internet gateway or public route unless you specifically need public connectivity.

**Done when:** the plan has no hard-coded resource IDs, and you can explain how Terraform determines creation order.

### 7. Data sources and outputs

Look up an existing AWS availability zone or default VPC with a data source, then use the returned values in a plan. Export only useful, non-sensitive values.

**Done when:** the configuration discovers the value rather than hard-coding it, and the output is understandable.

### 8. `for_each` and resource lifecycle

Create multiple resources from a map using `for_each`. Change one map entry and inspect the plan; compare the result with a `count`-based version.

Practice stable resource addresses and understand lifecycle options before using them.

**Done when:** changing one entry does not unnecessarily replace unrelated resources.

### 9. Remote state (optional, use a sandbox)

Configure an S3 backend with versioning and encryption, and restrict access to the state bucket. Follow the backend's bootstrap requirements and never commit state or backend credentials.

**Done when:** a second working directory can initialize against the same backend and see the expected state. Remove the backend only after safely destroying the managed resources.

### 10. Capstone: small, private AWS environment

Build a reusable configuration for a VPC, private subnet, and one small workload resource appropriate for your sandbox. Add variables, outputs, tags, and a README describing the architecture and estimated costs.

**Done when:** formatting and validation pass, the plan is reviewed, resources are verified in AWS, and a destroy completes without leftovers.

## Useful commands

```text
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
terraform destroy
```

For each lab, write down what you expected, what the plan showed, and what you learned. Keep `.terraform/`, `*.tfstate`, `*.tfstate.*`, and any secret variable files out of version control.
