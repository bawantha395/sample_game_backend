@echo off
REM Sample Game Backend - Terraform Deployment Script for Windows
REM This script helps deploy the infrastructure to AWS

setlocal enabledelayedexpansion

echo [INFO] Starting Terraform deployment...

REM Check if terraform is installed
where terraform >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform is not installed. Please install Terraform first.
    pause
    exit /b 1
)

REM Check if AWS CLI is installed
where aws >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] AWS CLI is not installed. Please install AWS CLI first.
    pause
    exit /b 1
)

REM Check if terraform.tfvars exists
if not exist "terraform.tfvars" (
    echo [WARNING] terraform.tfvars not found. Creating from example...
    if exist "terraform.tfvars.example" (
        copy terraform.tfvars.example terraform.tfvars
        echo [WARNING] Please edit terraform.tfvars with your values before running again.
        pause
        exit /b 1
    ) else (
        echo [ERROR] terraform.tfvars.example not found. Please create terraform.tfvars manually.
        pause
        exit /b 1
    )
)

REM Initialize Terraform
echo [INFO] Initializing Terraform...
terraform init
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
echo [INFO] Planning deployment...
terraform plan -out=tfplan
if %errorlevel% neq 0 (
    echo [ERROR] Terraform plan failed
    pause
    exit /b 1
)

REM Ask for confirmation
echo.
echo [WARNING] Review the plan above. Do you want to proceed with the deployment? (y/N)
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

echo [INFO] Deployment completed successfully!
echo.
echo [INFO] Next steps:
echo 1. Build and push your Docker image to ECR:
echo    aws ecr get-login-password --region %%AWS_REGION%% ^| docker login --username AWS --password-stdin %%ECR_URL%%
echo    docker build -t %%ECR_URL%% .
echo    docker push %%ECR_URL%%
echo.
echo 2. Your application will be available at:
for /f "tokens=*" %%i in ('terraform output -raw application_url') do echo    %%i
echo.
echo 3. Check ECS service status:
for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_id') do set CLUSTER_ID=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_service_name') do set SERVICE_NAME=%%i
echo    aws ecs describe-services --cluster %%CLUSTER_ID%% --services %%SERVICE_NAME%%

pause
