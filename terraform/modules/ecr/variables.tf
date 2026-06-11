variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}

variable "ecr_repository_url" {
  description = "Existing ECR repository URL (if any)"
  type        = string
  default     = ""
}
