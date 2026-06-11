#!/bin/bash

# Sample Game Backend - Terraform Deployment Script
# This script helps deploy the infrastructure to AWS for a specific environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Get environment from argument
ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    print_warning "No environment specified. Defaulting to 'dev'."
    ENVIRONMENT="dev"
fi

ENV_DIR="environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory $ENV_DIR not found."
    exit 1
fi

# Initialize Terraform
print_status "Initializing Terraform for environment: $ENVIRONMENT..."
terraform init -backend-config="$ENV_DIR/backend.hcl" -reconfigure

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan deployment
print_status "Planning deployment for $ENVIRONMENT..."
terraform plan -var-file="$ENV_DIR/terraform.tfvars" -out=tfplan

# Ask for confirmation
echo ""
print_warning "Review the plan above. Do you want to proceed with the deployment to $ENVIRONMENT? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled."
    exit 0
fi

# Apply deployment
print_status "Applying Terraform configuration..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

print_status "Deployment to $ENVIRONMENT completed successfully!"
echo ""
print_status "Next steps:"
echo "1. Build and push your Docker image to ECR:"
echo "   ./build-and-push.sh $ENVIRONMENT"
echo ""
echo "2. Your application will be available at:"
echo "   $(terraform output -raw application_url)"
echo ""
