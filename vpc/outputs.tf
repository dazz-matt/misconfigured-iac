# ***vpc/outputs.tf***

output "vpc_id" {
  value = aws_vpc.mb_vpc.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.mb_rds_subnet_group.*.name
}

output "db_security_group" {
  value = [aws_security_group.mb_security_group["rds"].id]
}

output "public_security_group" {
  value = aws_security_group.mb_security_group["public"].id
}

output "public_subnets" {
  value = aws_subnet.mb_public_subnet.*.id
}