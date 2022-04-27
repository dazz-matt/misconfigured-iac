# *** compute/variables.tf ***

variable "instance_count" {}
variable "instance_type" {}
variable "public_security_group" {}
variable "public_subnets" {}
variable "volume_size" {}
variable "key_name" {}
variable "public_key_path" {} #maybe add private key for super bad security misconfig?
variable "user_data_path" {}
variable "dbUser" {}
variable "dbName" {}
variable "dbPassword" {}
variable "db_endpoint" {}
variable "lb_target_group_arn" {}
variable "private_key_path" {}
variable "tg_port" {}