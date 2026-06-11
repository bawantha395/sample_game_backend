variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}

variable "app_port" {
  description = "Application port"
  type        = number
}
