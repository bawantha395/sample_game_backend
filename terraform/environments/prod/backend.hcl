bucket         = "sample-game-app-terraform-state-2026-06-09"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
