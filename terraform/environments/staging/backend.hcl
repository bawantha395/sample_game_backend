bucket         = "sample-game-app-terraform-state-2026-06-09"
key            = "staging/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
