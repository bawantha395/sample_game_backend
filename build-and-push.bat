@echo off
REM Sample Game Backend - Docker Build and Push Script for Windows
REM This script builds the Docker image and pushes it to ECR for a specific environment

setlocal enabledelayedexpansion

echo [INFO] Starting Docker build and push process...

REM Check if required tools are installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker first.
    exit /b 1
)

where aws >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] AWS CLI is not installed. Please install AWS CLI first.
    exit /b 1
)

where terraform >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform is not installed. Please install Terraform first.
    exit /b 1
)

REM Get environment from argument
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" (
    echo [WARNING] No environment specified. Defaulting to 'dev'.
    set ENVIRONMENT=dev
)

set ENV_DIR=environments\!ENVIRONMENT!

REM Check if terraform directory exists
if not exist "terraform" (
    echo [ERROR] Terraform directory not found. Please run this script from the project root.
    exit /b 1
)

REM Get outputs from Terraform
cd terraform

echo [INFO] Initializing Terraform for !ENVIRONMENT! to get outputs...
terraform init -backend-config="!ENV_DIR!/backend.hcl" -reconfigure > nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform initialization failed
    exit /b 1
)

for /f "tokens=*" %%i in ('terraform output -raw ecr_repository_url 2^>nul') do set ECR_URL=%%i
for /f "tokens=*" %%i in ('terraform output -raw aws_region 2^>nul') do set AWS_REGION=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_id 2^>nul') do set CLUSTER_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_service_name 2^>nul') do set SERVICE_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw application_url 2^>nul') do set APP_URL=%%i
cd ..

if "%ECR_URL%"=="" (
    echo [ERROR] Could not get ECR repository URL from Terraform output for !ENVIRONMENT!.
    exit /b 1
)

REM Extract cluster name from ARN if needed
for /f "tokens=6 delims=/" %%a in ("%CLUSTER_NAME%") do set CLUSTER_NAME=%%a

echo [INFO] Environment: !ENVIRONMENT!
echo [INFO] ECR Repository: %ECR_URL%
echo [INFO] AWS Region: %AWS_REGION%
echo [INFO] ECS Cluster: %CLUSTER_NAME%
echo [INFO] ECS Service: %SERVICE_NAME%

REM Login to ECR
echo [INFO] Logging in to ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_URL%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to login to ECR
    exit /b 1
)

REM Build Docker image
echo [INFO] Building Docker image...
docker build -t %ECR_URL%:latest .
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Docker image
    exit /b 1
)

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
docker tag %ECR_URL%:latest %ECR_URL%:%TIMESTAMP%

REM Push image to ECR
echo [INFO] Pushing image to ECR...
docker push %ECR_URL%:latest
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Docker image
    exit /b 1
)

docker push %ECR_URL%:%TIMESTAMP%

REM Update ECS service
echo [INFO] Updating ECS service...
aws ecs update-service --cluster %CLUSTER_NAME% --service %SERVICE_NAME% --force-new-deployment --region %AWS_REGION%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to update ECS service
    exit /b 1
)

REM Wait for deployment to complete
echo [INFO] Waiting for deployment to complete...
aws ecs wait services-stable --cluster %CLUSTER_NAME% --services %SERVICE_NAME% --region %AWS_REGION%
if %errorlevel% neq 0 (
    echo [WARNING] Deployment may not be stable yet. Check AWS Console for status.
)

echo [INFO] Deployment to !ENVIRONMENT! completed successfully!
echo [INFO] Application URL: %APP_URL%

pause
