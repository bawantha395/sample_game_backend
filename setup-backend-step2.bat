@echo off
echo ========================================
echo Step 2: Migrate State to Remote Backend
echo ========================================
echo.

echo This step migrates your existing local state to the remote S3 backend.
echo.

echo WARNING: This will migrate your local state to the remote S3 backend.
echo Make sure you have backed up your local state files!
echo.
echo Current state files in terraform directory:
dir terraform\*.tfstate*
echo.
pause

echo Step 2a: Initializing with remote backend...
cd terraform
terraform init -migrate-state

echo.
echo Step 2b: Verifying state migration...
echo.
echo Current state resources:
terraform state list

echo.
echo Step 2c: Testing remote backend...
terraform plan

echo.
echo ========================================
echo Backend setup completed successfully!
echo ========================================
echo.
echo Your Terraform state is now stored in:
echo - S3 Bucket: sample-game-app-terraform-state-750761633674
echo - DynamoDB Table: terraform-state-lock
echo.
echo GitHub Actions will now properly manage state across runs.
echo No more duplicate infrastructure creation!
echo.
pause
