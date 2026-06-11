terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend for GitHub Actions
  backend "s3" {
    bucket         = "sample-game-app-terraform-state-2026-06-09"
    key            = "sample-game-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-REPLACE_WITH_YOUR_ACCOUNT_ID"
  }
}
