variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}

variable "ses_verified_email" {
  description = "Verified email for SES"
  type        = string
}
