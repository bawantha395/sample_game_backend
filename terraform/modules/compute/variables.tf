variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "app_port" {
  description = "Application port"
  type        = number
}

variable "app_count" {
  description = "Number of application instances"
  type        = number
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = number
}

variable "memory" {
  description = "Memory for ECS task in MB"
  type        = number
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "db_address" {
  description = "Database address"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "ses_username" {
  description = "SES SMTP username"
  type        = string
  default     = ""
}

variable "ses_password" {
  description = "SES SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ses_verified_email" {
  description = "Verified email for SES"
  type        = string
  default     = ""
}

variable "ecs_tasks_sg_id" {
  description = "Security Group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "Target Group ARN for ALB"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "IAM Role ARN for ECS task execution"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "IAM Role ARN for ECS task"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}
