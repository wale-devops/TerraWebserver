############################################
# PROVIDER
############################################
provider "aws" {
  region = var.region
}

############################################
# VPC
############################################
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main_VPC"
  }
}

############################################
# SUBNETS
############################################
resource "aws_subnet" "jenkins_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Jenkins_sub"
  }
}

resource "aws_subnet" "docker_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Docker_sub"
  }
}

resource "aws_subnet" "free_sub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs[2]
  map_public_ip_on_launch = true

  tags = {
    Name = "Free_sub"
  }
}

############################################
# INTERNET GATEWAY
############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main_IGW"
  }
}

############################################
# ROUTE TABLE
############################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_RT"
  }
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
  description = "Allow SSH and Jenkins"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins"
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

  tags = {
    Name = "Main_SG"
  }
}

############################################
# EC2 INSTANCES
############################################

# Jenkins EC2
resource "aws_instance" "jenkins_ec2" {
  ami                    = var.amazon_linux_2023_ami
  instance_type          = var.instance_types["jenkins"]
  subnet_id              = aws_subnet.jenkins_sub.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y

              sudo wget -O /etc/yum.repos.d/jenkins.repo \
                https://pkg.jenkins.io/rpm-stable/jenkins.repo

              sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

              sudo yum upgrade -y

              sudo yum install java-21-amazon-corretto -y
              sudo yum install jenkins -y

              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF

  tags = {
    Name = "Jenkins EC2"
  }
}

# Docker EC2
resource "aws_instance" "docker_ec2" {
  ami                    = var.amazon_linux_2023_ami
  instance_type          = var.instance_types["docker"]
  subnet_id              = aws_subnet.docker_sub.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install git docker -y
              sudo systemctl enable docker
              sudo systemctl start docker
	      sudo yum install git -y
              EOF

  tags = {
    Name = "Docker EC2"
  }
}

# Free EC2
resource "aws_instance" "free_ec2" {
  ami                    = var.amazon_linux_2023_ami
  instance_type          = var.instance_types["free"]
  subnet_id              = aws_subnet.free_sub.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "Free EC2"
  }
}

############################################
# OUTPUTS
############################################
output "jenkins_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}

output "docker_public_ip" {
  value = aws_instance.docker_ec2.public_ip
}

output "free_public_ip" {
  value = aws_instance.free_ec2.public_ip
}

