# Copy this file to terraform.tfvars and update the values

# AWS Configuration
aws_region = "us-east-1"

# Application Configuration
app_name    = "sample-game-app"
environment = "prod"

# Database Configuration
db_username = "admin"
# db_password = "REMOVED_FOR_SECURITY"  # Use environment variable or GitHub secrets for production
db_instance_class = "db.t3.small"  # Use db.t3.small for production

# Application Configuration
app_port  = 8080
app_count = 2
cpu       = 512
memory    = 1024

# Domain Configuration (Optional)
domain_name = ""  # e.g., "api.yourdomain.com"
create_ssl_certificate = false

# SES Configuration (Optional)
ses_verified_email = ""  # e.g., "noreply@yourdomain.com"

# Tags
tags = {
  Project     = "Sample Game Backend"
  Environment = "prod"
  ManagedBy   = "terraform"
  Owner       = "learnfi"
}
