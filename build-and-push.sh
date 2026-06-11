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

# Get ECR repository URL and AWS region from Terraform
get_terraform_outputs() {
    if [ ! -d "terraform" ]; then
        print_error "Terraform directory not found. Please run this script from the project root."
        exit 1
    fi

    ENVIRONMENT=$1
    if [ -z "$ENVIRONMENT" ]; then
        print_warning "No environment specified. Defaulting to 'dev'."
        ENVIRONMENT="dev"
    fi

    ENV_DIR="environments/$ENVIRONMENT"
    cd terraform
    
    # Initialize for the specific environment to ensure we get the right outputs
    print_status "Initializing Terraform for $ENVIRONMENT to get outputs..."
    terraform init -backend-config="$ENV_DIR/backend.hcl" -reconfigure > /dev/null

    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null)
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null)
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_id 2>/dev/null | sed 's/.*\///')
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null)
    APP_URL=$(terraform output -raw application_url 2>/dev/null)
    cd ..

    if [ -z "$ECR_URL" ]; then
        print_error "Could not get ECR repository URL from Terraform output for $ENVIRONMENT."
        exit 1
    fi

    print_status "Environment: $ENVIRONMENT"
    print_status "ECR Repository: $ECR_URL"
    print_status "AWS Region: $AWS_REGION"
    print_status "ECS Cluster: $CLUSTER_NAME"
    print_status "ECS Service: $SERVICE_NAME"
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
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $AWS_REGION
}

# Wait for deployment to complete
wait_for_deployment() {
    print_status "Waiting for deployment to complete..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION
}

# Main execution
main() {
    print_status "Starting Docker build and push process..."
    
    ENVIRONMENT=$1
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi

    check_prerequisites
    get_terraform_outputs $ENVIRONMENT
    login_to_ecr
    build_image
    push_image
    update_ecs_service
    wait_for_deployment
    
    print_status "Deployment to $ENVIRONMENT completed successfully!"
    print_status "Application URL: $APP_URL"
}

# Run main function
main "$@"
