# ***root/variables.tf***

variable "aws_region" {
  default = "us-west-2"
}

variable "access_ip" {
  type = string
}

# ***Database Variables***

variable "dbName" {
  type = string
}

variable "dbUser" {
  type      = string
  sensitive = true #<-- change to false for misconfig alert?
}

variable "dbPassword" {
  type      = string
  sensitive = true #<-- change to false for misconfig alert?
}