# Terraform Backend Setup Guide

This guide explains how to set up the Terraform backend infrastructure for state management.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed locally
- Access to AWS account with permissions to create S3 buckets and DynamoDB tables

## Setup Steps

### 1. Store Secrets in GitHub
Ensure you have the following secrets set in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `DB_PASSWORD` (Valid password for RDS)
- `SES_USERNAME` (Optional, for email)
- `SES_PASSWORD` (Optional, for email)

The CI/CD pipeline is already configured to pick these up and pass them to Terraform.

### 2. Create S3 Bucket for Terraform State

You can use the `backend-setup.tf` file to create the infrastructure. It is configured to use your AWS Account ID to ensure the bucket name is unique globally.

```bash
cd terraform
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_state_lock
```

Alternatively, via CLI (replace `<YOUR_ACCOUNT_ID>`):

```bash
aws s3 mb s3://sample-game-app-tfstate-<YOUR_ACCOUNT_ID> --region us-east-1
```

### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

If the table already exists, you can skip this step or import it into your state.

### 3. Initialize Terraform

```bash
cd terraform
terraform init
```

## Verification

After running the above commands, verify the setup:

```bash
# Check S3 bucket exists
aws s3 ls s3://sample-game-app-tfstate-<YOUR_ACCOUNT_ID>

# Check DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock-<YOUR_ACCOUNT_ID> --region us-east-1

# Verify Terraform backend configuration
terraform init
```

## Important Notes

- **S3 Bucket Name**: Must be globally unique. Use `sample-game-app-tfstate-<YOUR_ACCOUNT_ID>`.
- **DynamoDB Table**: `terraform-state-lock-<YOUR_ACCOUNT_ID>` (for state locking).
- **Backend Configuration**: After creating the bucket and table, update `terraform/versions.tf` with the correct names before running the main deployment.
- **Database Password**: Must be at least 8 characters long and contain only printable ASCII characters (excluding `/`, `@`, `"`, and space). We use AWS SSM Parameter Store to securely pass the password to the application.

## Troubleshooting

### If RDS Password fails:
If you see `InvalidParameterValue: Invalid master password` from the AWS provider, it means your `db_password` secret is currently invalid for AWS RDS.

**Password Requirements:**
1. **Length**: At least 8 characters.
2. **Characters**: Only printable ASCII characters.
3. **Disallowed Characters**: Must **NOT** contain `/` (slash), `@` (at sign), `"` (double quote), or spaces.

**Immediate Fix:**
1. Go to your GitHub Repository.
2. Navigate to **Settings** -> **Secrets and variables** -> **Actions**.
3. Edit the `DB_PASSWORD` secret.
4. Set it to a valid value, for example: `MySafePassword2026!` (Note: avoid any trailing spaces when copy-pasting).
5. Re-run the failed GitHub Action.

### If S3 bucket already exists:
If you see `BucketAlreadyExists`, someone else might have taken the bucket name. In `backend-setup.tf`, we use your AWS Account ID to help prevent this. If it still fails, update the `bucket` name in `backend-setup.tf`.

### If DynamoDB table already exists:
If you get `ResourceInUseException: Table already exists`, it means the lock table was already created. In `backend-setup.tf`, we now use your AWS Account ID to make it unique. If you still encounter this, you can:
1. Use the existing table (it's compatible if the Hash Key is `LockID`).
2. Delete it and recreate: `aws dynamodb delete-table --table-name terraform-state-lock-<YOUR_ACCOUNT_ID> --region us-east-1`
3. Or import it: `terraform import aws_dynamodb_table.terraform_state_lock terraform-state-lock-<YOUR_ACCOUNT_ID>`

### If Terraform init fails:
1. Verify AWS credentials are configured
2. Check that S3 bucket and DynamoDB table exist
3. Ensure you have proper permissions
4. Check the backend configuration in `versions.tf`

## Backend Configuration

The backend is configured in `versions.tf`:

```hcl
backend "s3" {
  bucket         = "sample-game-app-tfstate-<YOUR_ACCOUNT_ID>"
  key            = "sample-game-app/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock-<YOUR_ACCOUNT_ID>"
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
