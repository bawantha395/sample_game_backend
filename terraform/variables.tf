variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of your application"
  type        = string
  default     = "sample-game-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8 && can(regex("^[a-zA-Z0-9!#$%&()*+,\\-.:;<=>?^\\[\\]_`{|}~]+$", var.db_password))
    error_message = "The db_password must be at least 8 characters long and contain only printable ASCII characters (excluding /, @, \", and space)."
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "app_count" {
  description = "Number of application instances"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 1024
}

variable "ecr_repository_url" {
  description = "Existing ECR repository URL (optional)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "create_ssl_certificate" {
  description = "Whether to create SSL certificate"
  type        = bool
  default     = false
}

variable "ses_verified_email" {
  description = "Verified email for SES (optional)"
  type        = string
  default     = ""
}

variable "ses_username" {
  description = "SES SMTP username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ses_password" {
  description = "SES SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Sample Game Backend"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
