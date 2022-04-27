# *** compute/main.tf ***

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "random_id" "mb_node_id" { #random id for each instance - remove for misconfig?
  byte_length = 2
  count       = var.instance_count
  keepers = { # for different ids for nodes
    key_name = var.key_name
  }
}

resource "aws_key_pair" "mb_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path) #hard code public key for misconfig?
}

resource "aws_instance" "mb_node" {
  count         = var.instance_count
  instance_type = var.instance_type #need t3.micro (free)
  ami           = data.aws_ami.server_ami.id
  tags = {
    Name = "mb_node-${random_id.mb_node_id[count.index].dec}"
  }


  key_name               = aws_key_pair.mb_auth.id
  vpc_security_group_ids = [var.public_security_group]
  subnet_id              = var.public_subnets[count.index]
  user_data = templatefile(var.user_data_path,
    {
      nodename    = "mb-${random_id.mb_node_id[count.index].dec}"
      db_endpoint = var.db_endpoint
      dbuser      = var.dbUser
      dbpass      = var.dbPassword
      dbname      = var.dbName
    }
  )
  root_block_device {
    volume_size = var.volume_size
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key = file(var.private_key_path)
    }
    script = "${path.root}/delay.sh"
  }
  provisioner "local-exec" {
    command = templatefile("${path.cwd}/scp_script.tpl",
      {
        nodeip   = self.public_ip
        k3s_path = "${path.cwd}/../"
        nodename = self.tags.Name
        private_key_path = var.private_key_path
      }
    )
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.cwd}/../k3s-${self.tags.Name}"
  }
}

resource "aws_lb_target_group_attachment" "mb_tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.mb_node[count.index].id
  port             = var.tg_port
}