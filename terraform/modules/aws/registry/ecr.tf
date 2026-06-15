resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-${var.app_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
