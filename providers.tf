terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  #use a variable for the region normally, but maybe keep to highlight Dazz feature?
  #region = "us-east-1"
  region = var.aws_region
}