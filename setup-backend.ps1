# PowerShell script to set up Terraform remote state backend
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setting up Terraform Remote State Backend" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "terraform")) {
    Write-Host "Error: terraform directory not found!" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Creating S3 bucket and DynamoDB table..." -ForegroundColor Yellow
Write-Host ""

# Navigate to terraform directory
Set-Location terraform

# Backup original versions.tf
Copy-Item "versions.tf" "versions.tf.backup" -Force

# Create temporary versions.tf without backend
$tempVersions = @"
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
"@

$tempVersions | Out-File -FilePath "versions.tf" -Encoding UTF8

Write-Host "Initializing Terraform..." -ForegroundColor Cyan
terraform init

Write-Host "Creating backend infrastructure..." -ForegroundColor Cyan
terraform apply -auto-approve -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state -target=aws_s3_bucket_public_access_block.terraform_state -target=aws_dynamodb_table.terraform_state_lock

Write-Host ""
Write-Host "Step 2: Migrating state to remote backend..." -ForegroundColor Yellow
Write-Host ""

# Restore original versions.tf with backend
Copy-Item "versions.tf.backup" "versions.tf" -Force

Write-Host "Migrating state to remote backend..." -ForegroundColor Cyan
terraform init -migrate-state

Write-Host ""
Write-Host "Verifying state migration..." -ForegroundColor Cyan
terraform state list

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backend setup completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your Terraform state is now stored in:" -ForegroundColor White
Write-Host "- S3 Bucket: sample-game-app-terraform-state-750761633674" -ForegroundColor White
Write-Host "- DynamoDB Table: terraform-state-lock" -ForegroundColor White
Write-Host ""
Write-Host "GitHub Actions will now properly manage state across runs." -ForegroundColor Green
Write-Host "No more duplicate infrastructure creation!" -ForegroundColor Green
Write-Host ""

# Return to original directory
Set-Location ..
