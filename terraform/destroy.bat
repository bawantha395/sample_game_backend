@echo off
REM Sample Game Backend - Terraform Destroy Script for Windows
REM This script helps destroy the infrastructure for a specific environment

setlocal enabledelayedexpansion

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

echo [WARNING] This will destroy ALL infrastructure resources for !ENVIRONMENT!!
echo [WARNING] This action cannot be undone!
echo.
echo [WARNING] Are you sure you want to proceed? (y/N)
set /p response=
if /i not "%response%"=="y" (
    echo [INFO] Destroy cancelled.
    pause
    exit /b 0
)

REM Plan destruction
echo [INFO] Planning destruction for !ENVIRONMENT!...
terraform plan -destroy -var-file="!ENV_DIR!/terraform.tfvars" -out=destroy.tfplan
if %errorlevel% neq 0 (
    echo [ERROR] Terraform plan failed
    pause
    exit /b 1
)

REM Ask for final confirmation
echo.
echo [WARNING] Review the destruction plan above. Do you want to proceed? (y/N)
set /p response=
if /i not "%response%"=="y" (
    echo [INFO] Destroy cancelled.
    del destroy.tfplan
    pause
    exit /b 0
)

REM Apply destruction
echo [INFO] Destroying infrastructure...
terraform apply destroy.tfplan
if %errorlevel% neq 0 (
    echo [ERROR] Terraform destroy failed
    pause
    exit /b 1
)

REM Clean up plan file
del destroy.tfplan

echo [INFO] Infrastructure for !ENVIRONMENT! destroyed successfully!
pause
