# Local values
locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.app_name
  })
}
