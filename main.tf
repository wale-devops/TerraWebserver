provider "aws" {
  region = var.region
}

module "webserver" {
  source = "./modules/webserver"

  vpc_cidr              = var.vpc_cidr
  subnet_cidrs          = var.subnet_cidrs
  instance_types        = var.instance_types
  key_name              = var.key_name
  root_volume_size      = var.root_volume_size
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  allowed_http_cidr     = var.allowed_http_cidr
  amazon_linux_2023_ami = var.amazon_linux_2023_ami
}

