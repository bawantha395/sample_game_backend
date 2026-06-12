# Sample Game Backend - Terraform Infrastructure

This directory contains Terraform configuration for deploying the Sample Game Backend application to AWS.

## Architecture

The infrastructure includes:

- **VPC** with public and private subnets across 2 availability zones
- **RDS MySQL** database in private subnets
- **ECS Fargate** cluster for running the Spring Boot application
- **Application Load Balancer** for traffic distribution
- **ECR** repository for Docker images
- **CloudWatch** for logging and monitoring
- **Auto Scaling** based on CPU utilization
- **Security Groups** for network access control

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0 installed
3. **Docker** for building and pushing images
4. **AWS Account** with sufficient permissions

## Quick Start

1. **Configure variables:**
   ```bash
   # Environment specific variables are in terraform/environments/{env}/terraform.tfvars
   ```

2. **Wait for CI/CD to deploy:**
   Push your changes to the `develop` or `prod` branch. The GitHub Actions pipeline will automatically:
   - Run tests
   - Provision infrastructure
   - Build and push the Docker image
   - Deploy to ECS

3. **Access your application:**
   Check the GitHub Action logs for the application URL or run:
   ```bash
   cd terraform/environments/dev # or staging, prod
   terraform output -raw application_url
   ```

## Configuration

### Required Variables

- `db_password`: Database password (sensitive)

### Optional Variables

- `aws_region`: AWS region (default: us-east-1)
- `app_name`: Application name (default: sample-game-app)
- `environment`: Environment name (default: dev)
- `db_instance_class`: RDS instance class (default: db.t3.micro)
- `app_count`: Number of application instances (default: 2)
- `cpu`: CPU units for ECS task (default: 512)
- `memory`: Memory for ECS task in MB (default: 1024)

## File Structure

```
terraform/
├── environments/         # Environment-specific standalone root configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
├── shared/               # Shared infrastructure (S3 backend, DynamoDB lock)
├── modules/              # Reusable infrastructure modules
│   ├── networking/       # VPC, Subnets, Gateways, Routing
│   ├── security/         # Security Groups
│   ├── iam/              # IAM Roles and Policies
│   ├── alb/              # Application Load Balancer
│   ├── ecr/              # ECR Repository
│   ├── compute/          # ECS Cluster, Service, Task Definition
│   └── database/         # RDS Instance and Subnet Group
├── global_variables.tf   # Centralized variable definitions (linked to environments)
└── README.md             # This file
```

### Centralized Variable Management
To reduce redundancy, all common variables are defined in `terraform/global_variables.tf`. Each environment folder (`dev`, `staging`, `prod`) contains a symbolic link to this file named `variables.tf`. 

- **To add a new variable**: Add it only to `terraform/global_variables.tf`.
- **To change a default**: Change it in `terraform/global_variables.tf`.
- **To provide environment values**: Update the `terraform.tfvars` file in the specific environment directory.

## Manual Deployment

If you prefer to run Terraform commands manually:

```bash
# Go to the environment directory
cd terraform/environments/dev

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Destroy (when needed)
terraform destroy
```

## Monitoring

- **CloudWatch Logs**: Application logs are sent to `/ecs/{app_name}-{environment}`
- **CloudWatch Alarms**: CPU and memory utilization alarms
- **ECS Service**: Monitor service health in AWS Console

## Security

- Database is in private subnets
- Application runs in private subnets
- Security groups restrict access
- RDS encryption enabled
- ECR image scanning enabled

## Cost Optimization

- Uses Fargate Spot instances (if available)
- Auto-scaling based on CPU utilization
- RDS instance can be resized based on needs
- CloudWatch logs retention set to 30 days

## Troubleshooting

### Common Issues

1. **ECS tasks not starting:**
   - Check CloudWatch logs
   - Verify ECR image exists and is accessible
   - Check security group rules

2. **Database connection issues:**
   - Verify RDS security group allows access from ECS
   - Check database credentials
   - Ensure RDS is in the same VPC

3. **Load balancer health checks failing:**
   - Verify application is responding on `/api/v1/application/version`
   - Check security group rules
   - Ensure application is binding to correct port

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster $(terraform output -raw ecs_cluster_id) --services $(terraform output -raw ecs_service_name)

# View application logs
aws logs tail /ecs/$(terraform output -raw ecs_cluster_id) --follow

# Check RDS status
aws rds describe-db-instances --db-instance-identifier $(terraform output -raw rds_identifier)
```

## Cleanup

To destroy resources for a specific environment, use the manual **Destroy** action in the GitHub Actions workflow.

Or manually from the environment directory:
```bash
terraform destroy
```

## Support

For issues or questions, please check:
1. AWS CloudWatch logs
2. ECS service events
3. Terraform state file
4. Application logs
