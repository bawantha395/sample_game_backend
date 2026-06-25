resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }
}

resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-game-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "game_db"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true

  apply_immediately    = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
}

# ==============================================================================
# AUTOMATED SECRETS MANAGER PROVISIONING (ADDED)
# ==============================================================================

# 1. Automatically builds the secure cloud container container vault inside AWS
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.environment}/game/db"
  recovery_window_in_days = 0 # Forces instant deletion on destroy so it never locks you out
}

# 2. Automatically json-encodes and writes the incoming pipeline password inside it
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({ password = var.db_password })
}