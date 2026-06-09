@echo off
echo ========================================
echo Setting up Terraform Remote State Backend
echo ========================================
echo.

echo Step 1: Creating S3 bucket and DynamoDB table for state management...
echo Current directory: %CD%
echo Changing to terraform directory...
cd terraform
echo Now in directory: %CD%
echo.

echo Initializing Terraform for backend setup...
terraform init
echo.

echo Creating S3 bucket and DynamoDB table...
terraform apply -auto-approve -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state -target=aws_s3_bucket_public_access_block.terraform_state -target=aws_dynamodb_table.terraform_state_lock

echo.
echo Step 2: Migrating existing state to remote backend...
echo.
echo WARNING: This will migrate your local state to the remote S3 backend.
echo Make sure you have backed up your local state files!
echo.
pause

echo Migrating state to remote backend...
terraform init -migrate-state

echo.
echo Step 3: Verifying state migration...
terraform state list

echo.
echo ========================================
echo Backend setup completed!
echo ========================================
echo.
echo Your Terraform state is now stored in:
echo - S3 Bucket: sample-game-app-terraform-state-750761633674
echo - DynamoDB Table: terraform-state-lock
echo.
echo GitHub Actions will now properly manage state across runs.
echo.
pause
