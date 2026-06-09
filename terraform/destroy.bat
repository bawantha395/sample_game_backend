@echo off
REM Sample Game Backend - Terraform Destroy Script for Windows
REM This script helps destroy the infrastructure

setlocal enabledelayedexpansion

echo [WARNING] This will destroy ALL infrastructure resources!
echo [WARNING] This action cannot be undone!
echo.
echo [WARNING] Are you sure you want to proceed? (y/N)
set /p response=
if /i not "%response%"=="y" (
    echo [INFO] Destroy cancelled.
    pause
    exit /b 0
)

REM Check if terraform is installed
where terraform >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform is not installed. Please install Terraform first.
    pause
    exit /b 1
)

REM Plan destruction
echo [INFO] Planning destruction...
terraform plan -destroy -out=destroy.tfplan
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

echo [INFO] Infrastructure destroyed successfully!
pause
