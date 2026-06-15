terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial Configuration: The pipeline will inject the bucket and dynamo table dynamically
  backend "s3" {
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}



# Root-level instantiation of modules using structural code mapping
module "foundation" {
  source               = "../../modules/aws/foundation"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  app_name             = var.app_name
}

module "registry" {
  source      = "../../modules/aws/registry"
  environment = var.environment
  app_name    = var.app_name
}

module "database" {
  source                        = "../../modules/aws/database"
  environment                   = var.environment
  db_instance_class             = "db.t2.micro"
  private_subnet_ids            = module.foundation.private_subnet_ids
  vpc_id                        = module.foundation.vpc_id
  db_username                   = var.db_username
  db_password                   = var.db_password
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
}

module "eks" {
  source             = "../../modules/aws/eks"
  environment        = var.environment
  app_name           = var.app_name
  private_subnet_ids = module.foundation.private_subnet_ids
  vpc_id             = module.foundation.vpc_id
}
