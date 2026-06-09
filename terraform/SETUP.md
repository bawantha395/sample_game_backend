# Terraform Backend Setup Guide

This guide explains how to set up the Terraform backend infrastructure for state management.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed locally
- Access to AWS account with permissions to create S3 buckets and DynamoDB tables

## Setup Steps

### 1. Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://sample-game-app-terraform-state-750761633674 --region us-east-1
```

### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

### 3. Initialize Terraform

```bash
cd terraform
terraform init
```

## Verification

After running the above commands, verify the setup:

```bash
# Check S3 bucket exists
aws s3 ls s3://sample-game-app-terraform-state-750761633674

# Check DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1

# Verify Terraform backend configuration
terraform init
```

## Important Notes

- **S3 Bucket Name**: `sample-game-app-terraform-state-750761633674` (contains AWS account ID)
- **DynamoDB Table**: `terraform-state-lock` (for state locking)
- **Region**: `us-east-1` (must match your Terraform configuration)
- **One-time Setup**: These resources are created once and shared across all environments

## Troubleshooting

### If S3 bucket already exists:
```bash
# Check if bucket exists
aws s3 ls s3://sample-game-app-terraform-state-750761633674
```

### If DynamoDB table already exists:
```bash
# Check table status
aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1
```

### If Terraform init fails:
1. Verify AWS credentials are configured
2. Check that S3 bucket and DynamoDB table exist
3. Ensure you have proper permissions
4. Check the backend configuration in `versions.tf`

## Backend Configuration

The backend is configured in `versions.tf`:

```hcl
backend "s3" {
  bucket         = "sample-game-app-terraform-state-750761633674"
  key            = "sample-game-app/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

## Workspace Management

After initialization, you can manage workspaces:

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev
terraform workspace new prod

# Switch workspace
terraform workspace select dev
terraform workspace select prod
```

## State and Workspaces

Terraform uses a state file (`terraform.tfstate`) to track all the resources it manages. A workspace is simply a separate copy of that state, so you can manage multiple environments — using the same code — safely.

Common workspace commands:

```bash
# List existing workspaces
terraform workspace list

# Select the production workspace
terraform workspace select prod

# Show the current workspace name
terraform workspace show

# Delete an unused workspace
terraform workspace delete prod-correct
```
