output "lb_target_group_arn" {
  value = aws_lb_target_group.mb_target_group.arn
}

output "lb_endpoint" {
  value = aws_lb.mb_lb.dns_name
}