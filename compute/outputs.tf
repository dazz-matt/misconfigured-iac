# ***compute/outputs.tf***

output "instance" {
  value     = aws_instance.mb_node[*]
  sensitive = true #comment out for misconfig?
}

output "instance_port" {
  value = aws_lb_target_group_attachment.mb_tg_attach[0].port
}