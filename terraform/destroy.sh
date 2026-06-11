#!/bin/bash

# Sample Game Backend - Terraform Destroy Script
# This script helps destroy the infrastructure for a specific environment

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

print_warning "This will destroy ALL infrastructure resources for $ENVIRONMENT!"
print_warning "This action cannot be undone!"
echo ""
print_warning "Are you sure you want to proceed? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Destroy cancelled."
    exit 0
fi

# Plan destruction
print_status "Planning destruction for $ENVIRONMENT..."
terraform plan -destroy -var-file="$ENV_DIR/terraform.tfvars" -out=destroy.tfplan

# Ask for final confirmation
echo ""
print_warning "Review the destruction plan above. Do you want to proceed? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Destroy cancelled."
    rm -f destroy.tfplan
    exit 0
fi

# Apply destruction
print_status "Destroying infrastructure..."
terraform apply destroy.tfplan

# Clean up plan file
rm -f destroy.tfplan

print_status "Infrastructure for $ENVIRONMENT destroyed successfully!"
