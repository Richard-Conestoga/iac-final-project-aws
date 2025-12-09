# Cloud Architecture and IaC - Final Project on AWS

This repository contains an Infrastructure as Code (IaC) project implementing AWS infrastructure using **Terraform** and **AWS CloudFormation**.  
The goal is to provision private and secure storage, compute, and database resources in an automated, modular, and reusable way.

---

## Project Overview

The project is split across both tools:

- **Terraform**
  - 4 private S3 buckets with versioning
  - Custom VPC and EC2 instance
  - MySQL RDS instance (`db.t3.micro`)
  - Local backend for Terraform state
- **CloudFormation (YAML)**
  - 3 private S3 buckets with `PublicAccessBlockConfiguration`
  - VPC + EC2 instance with networking components
  - MySQL RDS instance (`db.t3.micro`) with parameters and outputs

This demonstrates the ability to define and deploy AWS infrastructure declaratively using two different IaC technologies.

---

## Repository Structure

```

.
├── main.tf              \# Root Terraform configuration (resources + modules)
├── variables.tf         \# Terraform input variable definitions
├── terraform.tfvars     \# Terraform variable values (DO NOT COMMIT SENSITIVE DATA)
├── backend.tf           \# Terraform backend configuration (local state in this project)
├── s3.tf                \# Terraform S3 bucket resources (4 private buckets with versioning)
├── network.tf           \# Terraform VPC, subnets, IGW, routes, security groups
├── ec2.tf               \# Terraform EC2 instance in custom VPC
├── rds.tf               \# Terraform RDS MySQL instance and subnet group
│
├── s3-buckets.yaml      \# CloudFormation template for 3 private S3 buckets
├── vpc-ec2.yaml         \# CloudFormation template for VPC + EC2 + networking + output
├── rds.yaml             \# CloudFormation template for RDS MySQL with parameters
│
└── README.md            \# Project documentation

```

### Note on Terraform file layout

The project follows the instructor’s guidance conceptually:

- `main.tf` – main Terraform configuration (+ AWS provider block)
- `variables.tf` – input variable definitions
- `terraform.tfvars` – variable values (equivalent to the suggested `vars.tfvars`)
- `backend.tf` – backend configuration

The AWS `provider` block is defined in `main.tf` instead of a separate `provider.tf`, but the behavior is identical because Terraform loads all `.tf` files in the directory as a single configuration.


---

## Terraform: What It Deploys

### S3 (Terraform)

- Creates **4 private S3 buckets**.
- Bucket names are prefixed with the student ID (e.g. `8903530-...`).
- **Bucket versioning** is enabled on all buckets.
- Buckets are configured without public access.

### VPC and EC2 (Terraform)

- Custom VPC with:
  - CIDR block (e.g. `10.0.0.0/16`)
  - Public subnet (and an additional subnet for RDS)
  - Internet Gateway and route table for outbound internet access
- EC2 instance:
  - AMI ID and instance type provided as **variables**
  - Public IP enabled
  - Security Group allowing SSH on port 22
- Supports dynamic configuration via `variables.tf` and `terraform.tfvars`.

### RDS MySQL (Terraform)

- MySQL **RDS DB instance**:
  - Engine: MySQL (8.0)
  - Instance class: `db.t3.micro`
  - DB name, username, and password provided via **Terraform variables**
- **DB subnet group**:
  - Uses at least two subnets in different Availability Zones.
- **Security group**:
  - Allows MySQL traffic on port 3306 (e.g., from the EC2 security group).
- `publicly_accessible` enabled **only for this project** requirement.

### Terraform State / Backend

For this project, Terraform state is stored **locally**:

`backend.tf` (example):

```

terraform {
backend "local" {
path = "terraform.tfstate"
}
}

```

> In a team or production setting, a remote backend (e.g., S3 + DynamoDB) would be preferred.

---

## CloudFormation: What It Deploys

### S3 (CloudFormation – `s3-buckets.yaml`)

- Creates **3 private S3 buckets**.
- Each bucket uses `PublicAccessBlockConfiguration` to block:
  - Public ACLs
  - Public bucket policies
  - Public access to the bucket
- **Versioning** is enabled on each bucket.
- Bucket names are hardcoded with the student ID (e.g. `8903530-cfn-app1`).

Deployment example:

```

aws cloudformation deploy \
--template-file s3-buckets.yaml \
--stack-name s3-buckets-stack

```

---

### VPC + EC2 (CloudFormation – `vpc-ec2.yaml`)

- Custom VPC with:
  - CIDR block
  - Public subnet
  - Internet Gateway and route table
- EC2 instance:
  - Public subnet with `MapPublicIpOnLaunch`
  - Security group allowing SSH on port 22
  - Key pair referenced in the template
- **Output**:
  - Exposes the EC2 **Public IP** as a stack output (`InstancePublicIp`).

Deployment example:

```

aws cloudformation deploy \
--template-file vpc-ec2.yaml \
--stack-name vpc-ec2-stack

```

---

### RDS MySQL (CloudFormation – `rds.yaml`)

- MySQL **RDS DB instance**:
  - Engine: `mysql`
  - Instance class: parameterized (`DBInstanceClass`, default `db.t3.micro`)
  - Publicly accessible: `true` (as required for this project)
- **DB Subnet Group**:
  - Uses two subnets in different Availability Zones.
- **Security group**:
  - Allows inbound MySQL traffic on port 3306 (0.0.0.0/0 for project simplicity).
- **Parameters**:
  - `DBInstanceClass` (with allowed values)
  - `DBName`
  - `MasterUsername`
  - `MasterUserPassword` (with `NoEcho: true`)
- **Output**:
  - `RDSEndpoint` – the RDS endpoint address.

Deployment example:

```

aws cloudformation deploy \
--template-file rds.yaml \
--stack-name rds-stack \
--parameter-overrides \
DBInstanceClass=db.t3.micro \
DBName=appdb \
MasterUsername=dbadmin \
MasterUserPassword='SomeStrongPassword123!'

```

Retrieve endpoint:

```

aws cloudformation describe-stacks \
--stack-name rds-stack \
--query "Stacks.Outputs[?OutputKey=='RDSEndpoint'].OutputValue" \
--output text

```

---

## How to Run the Project

### Prerequisites

- AWS account and IAM user with appropriate permissions.
- AWS CLI configured (`aws configure`).
- Terraform installed (v1.x).
- A valid EC2 Key Pair in your region (used by Terraform and CFN EC2).

### Using Terraform

From the Terraform project directory:

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`.
2. Replace placeholder values (AMI ID, DB password, etc.) with real ones.

```

terraform init
terraform plan
terraform apply

```

- To tear down all Terraform-managed resources:

```

terraform destroy

```

### Using CloudFormation

Using AWS CLI:

```


# S3

aws cloudformation deploy \
--template-file s3-buckets.yaml \
--stack-name s3-buckets-stack

# VPC + EC2

aws cloudformation deploy \
--template-file vpc-ec2.yaml \
--stack-name vpc-ec2-stack

# RDS (with parameters)

aws cloudformation deploy \
--template-file rds.yaml \
--stack-name rds-stack \
--parameter-overrides \
DBInstanceClass=db.t3.micro \
DBName=appdb \
MasterUsername=dbadmin \
MasterUserPassword='SomeStrongPassword123!'

```

To delete stacks:

```

aws cloudformation delete-stack --stack-name s3-buckets-stack
aws cloudformation delete-stack --stack-name vpc-ec2-stack
aws cloudformation delete-stack --stack-name rds-stack

```

---

## Security and Best Practices

- S3 buckets are private and (for CFN) backed by `PublicAccessBlockConfiguration`.
- EC2 security groups restrict inbound traffic to **SSH (22)** only.
- RDS security groups restrict inbound traffic to **MySQL (3306)**.
- Sensitive data:
  - **Terraform**: credentials should not be committed in `terraform.tfvars` when pushing to GitHub.
  - **CloudFormation**: `MasterUserPassword` uses `NoEcho` to avoid logging in plaintext.

---

## Dynamic Configuration and Reusability

- Terraform:
  - Uses `variables.tf` and `terraform.tfvars` for AMI, instance type, DB credentials, etc.
- CloudFormation:
  - Uses **Parameters** in `rds.yaml` to configure DB instance class, DB name, username, and password at deploy time.
- Templates are reusable and can be adapted for different environments by changing parameters/variables rather than code.

---

## GitHub Repository

Repository name: `iac-final-project-aws` (public).

This repository contains:

- Terraform configurations (`*.tf`) including backend, variables, and resources.
- CloudFormation templates (`s3-buckets.yaml`, `vpc-ec2.yaml`, `rds.yaml`).
- This `README.md` documenting architecture, deployment, and design decisions.
```
