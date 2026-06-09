#!/bin/bash

# Development Environment Deployment Script
# This script deploys the application to the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Configuration
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
TERRAFORM_DIR="terraform"

print_header "Starting deployment to Development environment..."

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
}

# Build and push Docker image
build_and_push_image() {
    print_status "Building and pushing Docker image..."
    
    # Get ECR repository URL
    cd $TERRAFORM_DIR
    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    cd ..
    
    if [ -z "$ECR_URL" ]; then
        print_error "Could not get ECR repository URL. Please ensure infrastructure is deployed."
        exit 1
    fi
    
    print_status "ECR Repository: $ECR_URL"
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
    
    # Build and tag image
    docker build -t $ECR_URL:latest .
    docker tag $ECR_URL:latest $ECR_URL:dev-$(date +%Y%m%d-%H%M%S)
    
    # Push image
    docker push $ECR_URL:latest
    docker push $ECR_URL:dev-$(date +%Y%m%d-%H%M%S)
    
    print_status "Docker image pushed successfully"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure for development environment..."
    
    cd $TERRAFORM_DIR
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    
    # Plan deployment
    terraform plan -var="environment=$ENVIRONMENT" -var="db_password=$DB_PASSWORD"
    
    # Apply changes
    terraform apply -auto-approve -var="environment=$ENVIRONMENT" -var="db_password=$DB_PASSWORD"
    
    cd ..
    
    print_status "Infrastructure deployed successfully"
}

# Update ECS service
update_ecs_service() {
    print_status "Updating ECS service..."
    
    cd $TERRAFORM_DIR
    
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_id | sed 's/.*\///')
    SERVICE_NAME=$(terraform output -raw ecs_service_name)
    
    cd ..
    
    # Force new deployment
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $AWS_REGION
    
    print_status "ECS service update initiated"
}

# Wait for deployment to complete
wait_for_deployment() {
    print_status "Waiting for deployment to complete..."
    
    cd $TERRAFORM_DIR
    
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_id | sed 's/.*\///')
    SERVICE_NAME=$(terraform output -raw ecs_service_name)
    
    cd ..
    
    # Wait for service to be stable
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION
    
    print_status "Deployment completed successfully"
}

# Run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    cd $TERRAFORM_DIR
    APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "")
    cd ..
    
    if [ -n "$APP_URL" ]; then
        print_status "Application URL: $APP_URL"
        
        # Wait a bit for the application to start
        sleep 30
        
        # Check health endpoint
        if curl -f "$APP_URL/api/v1/application/version" > /dev/null 2>&1; then
            print_status "Health check passed"
        else
            print_warning "Health check failed - application may still be starting"
        fi
    else
        print_warning "Could not get application URL for health check"
    fi
}

# Main execution
main() {
    print_header "Development Environment Deployment"
    
    # Check if required environment variables are set
    if [ -z "$DB_PASSWORD" ]; then
        print_error "DB_PASSWORD environment variable is not set"
        exit 1
    fi
    
    check_prerequisites
    build_and_push_image
    deploy_infrastructure
    update_ecs_service
    wait_for_deployment
    run_health_checks
    
    print_status "Development deployment completed successfully! 🚀"
}

# Run main function
main "$@"
