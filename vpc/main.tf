# - - - vpc/main.tf - - -

# Datasources below
data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input = data.aws_availability_zones.available.names
  #hard code this value to make an insecure configuration
  result_count = var.max_subnets
}

resource "aws_vpc" "mb_vpc" {
  #don't hard code this, use a variable, but hard code this to show misconfig in demo
  cidr_block = var.vpc_cidr
  # will provide a dns host name for anything you deploy
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mb_vpc-${random_integer.random.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "mb_public_subnet" {
  #changing for public_subnet_count var, but change back to length(var.public_cidrs) for misconfig try
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.mb_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  #hard coding the below isn't the best way - maybe keep for Dazz demo
  #maybe remove the "count.index" to go through all of them for a misconfig?
  #uncomment out the below for a misconfig?
  #availability_zone = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"][count.index]
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "mb_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "mb_public_association" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.mb_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.mb_public_route_table.id
}

resource "aws_subnet" "mb_private_subnet" {
  #changing for private_subnet_count var, but change back to length(var.private_cidrs) for misconfig try
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.mb_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false #since these are private, maybe make true for a misconfig?
  #hard coding the below isn't the best way - maybe keep for Dazz demo
  #maybe remove the "count.index" to go through all of them for a misconfig?
  #uncomment out the below for a misconfig?
  #availability_zone = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"][count.index]
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "mb_private_${count.index + 1}"
  }
}

resource "aws_internet_gateway" "mb_internet_gateway" {
  vpc_id = aws_vpc.mb_vpc.id

  tags = {
    Name = "mb_internet_gateway"
  }
}

resource "aws_route_table" "mb_public_route_table" {
  vpc_id = aws_vpc.mb_vpc.id

  tags = {
    Name = "mb_public"
  }
}

#default route is where all traffice goes that isn't specifically destined for something:
#will send traffic wherever we want it to
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mb_public_route_table.id
  destination_cidr_block = "0.0.0.0/0" #<-- all ip addresses
  gateway_id             = aws_internet_gateway.mb_internet_gateway.id
}

#default route TABLE are the subnets used if they haven't been explicitly associated with one
resource "aws_default_route_table" "mb_private_route_table" {
  #every vpc gets a default route tabe, specified the default route table created by the vpc is going to be the
  #default route table for our infrastructure
  default_route_table_id = aws_vpc.mb_vpc.default_route_table_id

  tags = {
    Name = "mb_private"
  }
}

resource "aws_security_group" "mb_security_group" {
  for_each    = var.security_groups
  name        = each.value.name        #"public_security_group"
  description = each.value.description #"Security group for public access"
  vpc_id      = aws_vpc.mb_vpc.id
  #setting up ssh
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port = ingress.value.from     #22
      to_port   = ingress.value.to       #22
      protocol  = ingress.value.protocol #"tcp"
      #maybe put a hardcoded ip address for a misconfig?
      cidr_blocks = ingress.value.cidr_blocks #[var.access_ip] #needs to be a list
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "mb_rds_subnet_group" {
  count      = var.db_subnet_group == true ? 1 : 0 #1 to deploy subnet group, 0 to not
  name       = "mb_rds_subnet_group"
  subnet_ids = aws_subnet.mb_private_subnet.*.id
  tags = {
    Name = "mb_rds_subnet_group"
  }
}