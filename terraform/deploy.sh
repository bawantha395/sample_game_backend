#!/bin/bash

# Sample Game Backend - Terraform Deployment Script
# This script helps deploy the infrastructure to AWS

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

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your values before running again."
        exit 1
    else
        print_error "terraform.tfvars.example not found. Please create terraform.tfvars manually."
        exit 1
    fi
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan deployment
print_status "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
print_warning "Review the plan above. Do you want to proceed with the deployment? (y/N)"
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

print_status "Deployment completed successfully!"
echo ""
print_status "Next steps:"
echo "1. Build and push your Docker image to ECR:"
echo "   aws ecr get-login-password --region \$(terraform output -raw aws_region) | docker login --username AWS --password-stdin \$(terraform output -raw ecr_repository_url)"
echo "   docker build -t \$(terraform output -raw ecr_repository_url) ."
echo "   docker push \$(terraform output -raw ecr_repository_url)"
echo ""
echo "2. Your application will be available at:"
echo "   \$(terraform output -raw application_url)"
echo ""
echo "3. Check ECS service status:"
echo "   aws ecs describe-services --cluster \$(terraform output -raw ecs_cluster_id) --services \$(terraform output -raw ecs_service_name)"
