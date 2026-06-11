@echo off
REM Sample Game Backend - Terraform Deployment Script for Windows
REM This script helps deploy the infrastructure to AWS for a specific environment

setlocal enabledelayedexpansion

echo [INFO] Starting Terraform deployment...

REM Check if terraform is installed
where terraform >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform is not installed. Please install Terraform first.
    pause
    exit /b 1
)

REM Get environment from argument
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" (
    echo [WARNING] No environment specified. Defaulting to 'dev'.
    set ENVIRONMENT=dev
)

set ENV_DIR=environments\!ENVIRONMENT!

if not exist "!ENV_DIR!" (
    echo [ERROR] Environment directory !ENV_DIR! not found.
    pause
    exit /b 1
)

REM Initialize Terraform
echo [INFO] Initializing Terraform for environment: !ENVIRONMENT!...
terraform init -backend-config="!ENV_DIR!/backend.hcl" -reconfigure
if %errorlevel% neq 0 (
    echo [ERROR] Terraform initialization failed
    pause
    exit /b 1
)

REM Validate configuration
echo [INFO] Validating Terraform configuration...
terraform validate
if %errorlevel% neq 0 (
    echo [ERROR] Terraform validation failed
    pause
    exit /b 1
)

REM Plan deployment
echo [INFO] Planning deployment for !ENVIRONMENT!...
terraform plan -var-file="!ENV_DIR!/terraform.tfvars" -out=tfplan
if %errorlevel% neq 0 (
    echo [ERROR] Terraform plan failed
    pause
    exit /b 1
)

REM Ask for confirmation
echo.
echo [WARNING] Review the plan above. Do you want to proceed with the deployment to !ENVIRONMENT!? (y/N)
set /p response=
if /i not "%response%"=="y" (
    echo [INFO] Deployment cancelled.
    pause
    exit /b 0
)

REM Apply deployment
echo [INFO] Applying Terraform configuration...
terraform apply tfplan
if %errorlevel% neq 0 (
    echo [ERROR] Terraform apply failed
    pause
    exit /b 1
)

REM Clean up plan file
del tfplan

echo [INFO] Deployment to !ENVIRONMENT! completed successfully!
echo.
echo [INFO] Next steps:
echo 1. Build and push your Docker image to ECR:
echo    ..\build-and-push.bat !ENVIRONMENT!
echo.
echo 2. Your application will be available at:
for /f "tokens=*" %%i in ('terraform output -raw application_url') do echo    %%i
echo.

pause
