module "networking" {
  source = "./modules/networking"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  availability_zones = data.aws_availability_zones.available.names
}

module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
  vpc_id      = module.networking.vpc_id
  app_port    = var.app_port
}

module "iam" {
  source = "./modules/iam"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  ses_verified_email = var.ses_verified_email
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  common_tags       = local.common_tags
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  app_port          = var.app_port
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  ecr_repository_url = var.ecr_repository_url
}

module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  private_subnet_ids = module.networking.private_subnet_ids
  aws_region         = var.aws_region
  app_port           = var.app_port
  app_count          = var.app_count
  cpu                = var.cpu
  memory             = var.memory

  db_address         = module.database.db_instance_address
  db_username        = var.db_username
  db_password        = var.db_password
  ses_username       = var.ses_username
  ses_password       = var.ses_password
  ses_verified_email = var.ses_verified_email

  ecs_tasks_sg_id             = module.security.ecs_tasks_sg_id
  target_group_arn            = module.alb.target_group_arn
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.iam.ecs_task_role_arn
  ecr_repository_url          = module.ecr.repository_url
}

module "database" {
  source = "./modules/database"

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  private_subnet_ids = module.networking.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
  db_sg_id           = module.security.rds_sg_id
}