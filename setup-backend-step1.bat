@echo off
echo ========================================
echo Step 1: Create S3 Bucket and DynamoDB Table
echo ========================================
echo.

echo This step creates the S3 bucket and DynamoDB table for Terraform state.
echo We need to temporarily disable the backend configuration.
echo.

echo Step 1a: Temporarily disabling backend configuration...
cd terraform
copy versions.tf versions.tf.backup
echo.

echo Step 1b: Creating temporary versions.tf without backend...
(
echo terraform {
echo   required_version = ">= 1.5.0"
echo   required_providers {
echo     aws = {
echo       source  = "hashicorp/aws"
echo       version = "~> 5.0"
echo     }
echo   }
echo }
) > versions.tf.temp
move versions.tf.temp versions.tf
echo.

echo Step 1c: Initializing Terraform...
terraform init
echo.

echo Step 1d: Creating backend infrastructure...
terraform apply -auto-approve -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state -target=aws_s3_bucket_public_access_block.terraform_state -target=aws_dynamodb_table.terraform_state_lock

echo.
echo Step 1e: Restoring original versions.tf with backend configuration...
move versions.tf.backup versions.tf
echo.

echo ========================================
echo Step 1 completed! Backend infrastructure created.
echo ========================================
echo.
echo Next: Run setup-backend-step2.bat to migrate your state.
echo.
pause
