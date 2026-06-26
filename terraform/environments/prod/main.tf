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

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Root-level instantiation of modules using structural code mapping
module "foundation" {
  source               = "../../modules/aws/foundation"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "registry" {
  source      = "../../modules/aws/registry"
  environment = var.environment
  app_name    = var.app_name
}

module "database" {
  source                        = "../../modules/aws/database"
  environment                   = var.environment
  db_instance_class             = "db.t3.micro"
  private_subnet_ids            = module.foundation.private_subnet_ids
  vpc_id                        = module.foundation.vpc_id
  db_username                   = var.db_username
  db_password                   = var.db_password
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
}

module "eks" {
  source              = "../../modules/aws/eks"
  environment         = var.environment
  cluster_name        = "prod-issue-app-cluster"
  kubernetes_version  = "1.30"
  private_subnet_ids  = module.foundation.private_subnet_ids
  vpc_id              = module.foundation.vpc_id
  node_min_size       = 1
  node_desired_size   = 2
  node_max_size       = 3
  node_instance_types = ["t3.small"]
}

module "dns_cdn" {
  source      = "../../modules/aws/dns_cdn"
  environment = var.environment
  domain_name = "tcmslk.me"
  # Note: alb_dns_name should be fetched from the ALB created by the Ingress controller
  # In a real scenario, you might need to use a data source or hardcode it after first run
  alb_dns_name = "k8s-issueapp-microser-xxxxxxxxxx.us-east-1.elb.amazonaws.com" 

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
