#!/bin/bash

# Sample Game Backend - Terraform Destroy Script
# This script helps destroy the infrastructure

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

print_warning "This will destroy ALL infrastructure resources!"
print_warning "This action cannot be undone!"
echo ""
print_warning "Are you sure you want to proceed? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Destroy cancelled."
    exit 0
fi

# Plan destruction
print_status "Planning destruction..."
terraform plan -destroy -out=destroy.tfplan

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

print_status "Infrastructure destroyed successfully!"
