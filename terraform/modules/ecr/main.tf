# ECR Repository
resource "aws_ecr_repository" "app" {
  count                = var.ecr_repository_url == "" ? 1 : 0
  name                 = "${var.name_prefix}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}

locals {
  ecr_repo_url = var.ecr_repository_url == "" ? aws_ecr_repository.app[0].repository_url : var.ecr_repository_url
  ecr_repo_name = var.ecr_repository_url == "" ? aws_ecr_repository.app[0].name : split("/", var.ecr_repository_url)[1]
}
