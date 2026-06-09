#!/bin/bash

# Sample Game Backend - Docker Build and Push Script
# This script builds the Docker image and pushes it to ECR

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

# Check if required tools are installed
check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
}

# Get ECR repository URL from Terraform
get_ecr_url() {
    if [ ! -d "terraform" ]; then
        print_error "Terraform directory not found. Please run this script from the project root."
        exit 1
    fi

    cd terraform
    if [ ! -f "terraform.tfstate" ]; then
        print_error "Terraform state not found. Please deploy infrastructure first using ./terraform/deploy.sh"
        exit 1
    fi

    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null)
    cd ..

    if [ -z "$ECR_URL" ]; then
        print_error "Could not get ECR repository URL from Terraform output."
        exit 1
    fi

    print_status "ECR Repository: $ECR_URL"
    print_status "AWS Region: $AWS_REGION"
}

# Login to ECR
login_to_ecr() {
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    docker build -t $ECR_URL:latest .
    docker tag $ECR_URL:latest $ECR_URL:$(date +%Y%m%d-%H%M%S)
}

# Push image to ECR
push_image() {
    print_status "Pushing image to ECR..."
    docker push $ECR_URL:latest
    docker push $ECR_URL:$(date +%Y%m%d-%H%M%S)
}

# Update ECS service
update_ecs_service() {
    print_status "Updating ECS service..."
    CLUSTER_NAME=$(cd terraform && terraform output -raw ecs_cluster_id | sed 's/.*\///')
    SERVICE_NAME=$(cd terraform && terraform output -raw ecs_service_name)
    
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $AWS_REGION
}

# Wait for deployment to complete
wait_for_deployment() {
    print_status "Waiting for deployment to complete..."
    CLUSTER_NAME=$(cd terraform && terraform output -raw ecs_cluster_id | sed 's/.*\///')
    SERVICE_NAME=$(cd terraform && terraform output -raw ecs_service_name)
    
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION
}

# Main execution
main() {
    print_status "Starting Docker build and push process..."
    
    check_prerequisites
    get_ecr_url
    login_to_ecr
    build_image
    push_image
    update_ecs_service
    wait_for_deployment
    
    print_status "Deployment completed successfully!"
    print_status "Application URL: $(cd terraform && terraform output -raw application_url)"
}

# Run main function
main "$@"
