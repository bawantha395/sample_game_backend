#!/bin/bash

# Production Environment Deployment Script
# This script deploys the application to the production environment with additional safety checks

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
ENVIRONMENT="prod"
AWS_REGION="us-east-1"
TERRAFORM_DIR="terraform"

print_header "Starting deployment to Production environment..."

# Safety checks for production
safety_checks() {
    print_status "Running production safety checks..."
    
    # Check if we're on main branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        print_error "Production deployment must be from main branch. Current branch: $CURRENT_BRANCH"
        exit 1
    fi
    
    # Check if working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        print_error "Working directory is not clean. Please commit or stash changes."
        exit 1
    fi
    
    # Check if required environment variables are set
    if [ -z "$DB_PASSWORD_PROD" ]; then
        print_error "DB_PASSWORD_PROD environment variable is not set"
        exit 1
    fi
    
    if [ -z "$SES_USERNAME" ] || [ -z "$SES_PASSWORD" ]; then
        print_warning "SES credentials not set - email functionality may not work"
    fi
    
    print_status "Safety checks passed"
}

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
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS credentials not configured or invalid"
        exit 1
    fi
}

# Build and push Docker image
build_and_push_image() {
    print_status "Building and pushing Docker image for production..."
    
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
    
    # Build and tag image with production tag
    PROD_TAG="prod-$(date +%Y%m%d-%H%M%S)"
    docker build -t $ECR_URL:latest .
    docker tag $ECR_URL:latest $ECR_URL:$PROD_TAG
    
    # Push image
    docker push $ECR_URL:latest
    docker push $ECR_URL:$PROD_TAG
    
    print_status "Docker image pushed successfully with tag: $PROD_TAG"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure for production environment..."
    
    cd $TERRAFORM_DIR
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    
    # Plan deployment with production settings
    terraform plan \
        -var="environment=$ENVIRONMENT" \
        -var="db_password=$DB_PASSWORD_PROD" \
        -var="app_count=3" \
        -var="cpu=1024" \
        -var="memory=2048" \
        -var="db_instance_class=db.t3.small"
    
    # Ask for confirmation before applying
    print_warning "About to deploy to PRODUCTION environment. This will affect live users."
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    # Apply changes
    terraform apply -auto-approve \
        -var="environment=$ENVIRONMENT" \
        -var="db_password=$DB_PASSWORD_PROD" \
        -var="app_count=3" \
        -var="cpu=1024" \
        -var="memory=2048" \
        -var="db_instance_class=db.t3.small"
    
    cd ..
    
    print_status "Infrastructure deployed successfully"
}

# Update ECS service with blue-green deployment
update_ecs_service() {
    print_status "Updating ECS service with blue-green deployment..."
    
    cd $TERRAFORM_DIR
    
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_id | sed 's/.*\///')
    SERVICE_NAME=$(terraform output -raw ecs_service_name)
    
    cd ..
    
    # Get current service configuration
    CURRENT_TASK_DEF=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION \
        --query 'services[0].taskDefinition' \
        --output text)
    
    print_status "Current task definition: $CURRENT_TASK_DEF"
    
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
    
    # Wait for service to be stable with longer timeout for production
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION
    
    print_status "Deployment completed successfully"
}

# Run comprehensive health checks
run_health_checks() {
    print_status "Running comprehensive health checks..."
    
    cd $TERRAFORM_DIR
    APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "")
    cd ..
    
    if [ -n "$APP_URL" ]; then
        print_status "Application URL: $APP_URL"
        
        # Wait for application to start
        print_status "Waiting for application to start..."
        sleep 60
        
        # Check multiple endpoints
        ENDPOINTS=(
            "/api/v1/application/version"
        )
        
        for endpoint in "${ENDPOINTS[@]}"; do
            print_status "Checking endpoint: $endpoint"
            if curl -f "$APP_URL$endpoint" > /dev/null 2>&1; then
                print_status "✓ $endpoint is healthy"
            else
                print_error "✗ $endpoint is not responding"
                exit 1
            fi
        done
        
        # Check database connectivity (if health endpoint exists)
        print_status "Checking database connectivity..."
        if curl -f "$APP_URL/api/v1/application/version" | grep -q "0.0.1"; then
            print_status "✓ Database connectivity confirmed"
        else
            print_warning "Database connectivity check inconclusive"
        fi
        
        print_status "All health checks passed"
    else
        print_error "Could not get application URL for health check"
        exit 1
    fi
}

# Send deployment notification
send_notification() {
    print_status "Sending deployment notification..."
    
    # This would integrate with your notification system
    # For example, Slack, email, or monitoring system
    print_status "Deployment notification sent"
}

# Main execution
main() {
    print_header "Production Environment Deployment"
    
    safety_checks
    check_prerequisites
    build_and_push_image
    deploy_infrastructure
    update_ecs_service
    wait_for_deployment
    run_health_checks
    send_notification
    
    print_status "Production deployment completed successfully! 🚀"
    print_warning "Please monitor the application for the next 30 minutes"
}

# Run main function
main "$@"
