# PowerShell script to create S3 bucket and DynamoDB table for Terraform state
Write-Host "========================================" -ForegroundColor Green
Write-Host "Creating Terraform State Backend" -ForegroundColor Green
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

# Create S3 bucket using AWS CLI
Write-Host "Creating S3 bucket..." -ForegroundColor Cyan
aws s3 mb s3://sample-game-app-terraform-state-750761633674 --region us-east-1

# Enable versioning
Write-Host "Enabling S3 bucket versioning..." -ForegroundColor Cyan
aws s3api put-bucket-versioning --bucket sample-game-app-terraform-state-750761633674 --versioning-configuration Status=Enabled

# Enable encryption
Write-Host "Enabling S3 bucket encryption..." -ForegroundColor Cyan
aws s3api put-bucket-encryption --bucket sample-game-app-terraform-state-750761633674 --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'

# Block public access
Write-Host "Blocking public access..." -ForegroundColor Cyan
aws s3api put-public-access-block --bucket sample-game-app-terraform-state-750761633674 --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table
Write-Host "Creating DynamoDB table..." -ForegroundColor Cyan
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1

Write-Host ""
Write-Host "Waiting for resources to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Step 2: Initializing Terraform with remote backend..." -ForegroundColor Yellow
Write-Host ""

# Initialize Terraform with remote backend
Write-Host "Initializing Terraform..." -ForegroundColor Cyan
terraform init

Write-Host ""
Write-Host "Step 3: Migrating existing state..." -ForegroundColor Yellow
Write-Host ""

# Check if we have existing state to migrate
if (Test-Path "terraform.tfstate" -and (Get-Content "terraform.tfstate" | ConvertFrom-Json).resources.Count -gt 0) {
    Write-Host "Found existing state. Migrating to remote backend..." -ForegroundColor Cyan
    terraform init -migrate-state
} else {
    Write-Host "No existing state found. Remote backend is ready." -ForegroundColor Green
}

Write-Host ""
Write-Host "Verifying setup..." -ForegroundColor Cyan
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
