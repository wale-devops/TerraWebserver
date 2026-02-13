############################################
# VPC
############################################
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "Main_VPC" }
}

############################################
# SUBNETS
############################################
resource "aws_subnet" "jenkins_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[0]
  map_public_ip_on_launch = true
  tags = { Name = "Jenkins_sub" }
}

resource "aws_subnet" "docker_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[1]
  map_public_ip_on_launch = true
  tags = { Name = "Docker_sub" }
}

resource "aws_subnet" "free_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[2]
  map_public_ip_on_launch = true
  tags = { Name = "Free_sub" }
}

############################################
# INTERNET GATEWAY & ROUTE TABLE
############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "Main_IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Public_RT" }
}

resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_sub.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "docker_rta" {
  subnet_id      = aws_subnet.docker_sub.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "free_rta" {
  subnet_id      = aws_subnet.free_sub.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# SECURITY GROUP
############################################
resource "aws_security_group" "main_sg" {
  name        = "main_sg"
  description = "Allow SSH and Jenkins/Docker"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP/Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_http_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Main_SG" }
}

############################################
# EC2 INSTANCES (dynamic with for_each)
############################################
locals {
  subnet_map = {
    jenkins = aws_subnet.jenkins_sub.id
    docker  = aws_subnet.docker_sub.id
    free    = aws_subnet.free_sub.id
  }

  user_data_map = {
    jenkins = <<-EOF
      #!/bin/bash
      sudo dnf update -y
      sudo dnf install -y java-21-amazon-corretto wget
      sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
      sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
      sudo dnf install -y jenkins
      sudo systemctl enable jenkins
      sudo systemctl start jenkins
    EOF

    docker = <<-EOF
      #!/bin/bash
      sudo dnf update -y
      sudo dnf install -y docker git
      sudo systemctl enable docker
      sudo systemctl start docker
      sudo usermod -aG docker ec2-user
    EOF

    free = ""
  }
}

resource "aws_instance" "servers" {
  for_each = var.instance_types

  ami                    = var.amazon_linux_2023_ami
  instance_type          = each.value
  subnet_id              = local.subnet_map[each.key]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  user_data              = local.user_data_map[each.key]

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${each.key}_ec2"
  }
}

