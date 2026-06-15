module "foundation" {
  source = "../../modules/aws/foundation"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "eks" {
  source = "../../modules/aws/eks"

  environment        = var.environment
  cluster_name       = "game-app"
  kubernetes_version = "1.29"
  
  vpc_id             = module.foundation.vpc_id
  private_subnet_ids = module.foundation.private_subnet_ids

  node_desired_size   = 3
  node_max_size       = 10
  node_min_size       = 3
  node_instance_types = ["t3.large"]
}

module "registry" {
  source      = "../../modules/aws/registry"
  environment = var.environment
  app_name    = var.app_name
}

module "database" {
  source                        = "../../modules/aws/database"
  environment                   = var.environment
  vpc_id                        = module.foundation.vpc_id
  private_subnet_ids            = module.foundation.private_subnet_ids
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  db_instance_class             = "db.t3.small"
  db_username                   = var.db_username
  db_password                   = var.db_password
}
# Manual Trigger Force
