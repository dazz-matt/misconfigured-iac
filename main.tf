# - - - root/main.tf - - - 

module "vpc" {
  source               = "./vpc"
  vpc_cidr             = local.vpc_cidr
  access_ip            = var.access_ip
  security_groups      = local.security_groups
  public_subnet_count  = 2
  private_subnet_count = 3
  max_subnets          = 20
  #maybe uncomment below for misconfig:
  #public_cidrs = ["10.123.2.0/24", "10.123.4.0/24"]
  #doing same as above, but dynamically chaning IPs:
  public_cidrs = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  #maybe uncomment below for misconfig:
  #private_cidrs = ["10.123.1.0/24", "10.123.3.0/24", "10.123.5.0/24"]
  private_cidrs   = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group = true
}

module "database" {
  source                 = "./database"
  db_storage             = 10
  db_engine_version      = "5.7.22"
  db_instance_class      = "db.t2.micro"
  dbName                 = var.dbName
  dbUser                 = var.dbUser
  dbPassword             = var.dbPassword #sensitive value, auto set by AWS
  db_identifier          = "mb-db"
  skip_db_snapshot       = true #in prod, would probably set to false
  db_subnet_group_name   = module.vpc.db_subnet_group_name[0]
  vpc_security_group_ids = module.vpc.db_security_group
}

module "loadbalancing" {
  source                 = "./loadbalancing"
  public_security_group  = module.vpc.public_security_group
  public_subnets         = module.vpc.public_subnets
  tg_port                = 80
  tg_protocol            = "HTTP"
  vpc_id                 = module.vpc.vpc_id
  lb_healthy_threshold   = 2
  lb_unhealthy_threshold = 2
  lb_timeout             = 3
  lb_interval            = 30
  listener_port          = 8000
  listener_protocol      = "HTTP"
}

module "compute" {
  source                = "./compute"
  public_security_group = module.vpc.public_security_group
  public_subnets        = module.vpc.public_subnets
  instance_count        = 1
  instance_type         = "t3.micro"
  volume_size           = 10
  public_key_path       = "/Users/mattbrown/.ssh/keymb.pub" #send private key for misconfig?
  key_name              = "keymb"
  user_data_path        = "${path.root}/userdata.tpl"
  dbName                = var.dbName
  dbUser                = var.dbUser
  dbPassword            = var.dbPassword
  db_endpoint           = module.database.db_endpoint
  lb_target_group_arn   = module.loadbalancing.lb_target_group_arn
  tg_port               = 8000
  private_key_path = "/Users/mattbrown/.ssh/keymb"
}