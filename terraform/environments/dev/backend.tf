terraform {
  backend "s3" {
    bucket         = "sample-game-app-terraform-state-2026"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
