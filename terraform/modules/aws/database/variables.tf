variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "eks_cluster_security_group_id" { type = string }
variable "db_instance_class" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "tags" { type = map(string) default = {} }
