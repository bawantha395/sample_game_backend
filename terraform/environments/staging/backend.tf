terraform {
  backend "s3" {
    bucket         = "sample-game-app-tfstate-530352103493"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-530352103493"
  }
}
