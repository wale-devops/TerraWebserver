variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_cidrs" {
  description = "List of subnet CIDRs [Jenkins, Docker, Free]"
  type        = list(string)
}

variable "instance_types" {
  description = "Map of instance types for each EC2: jenkins, docker, free"
  type        = map(string)
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size (GiB)"
  type        = number
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH"
  type        = string
}

variable "allowed_http_cidr" {
  description = "CIDR allowed for HTTP/Jenkins"
  type        = string
}

variable "amazon_linux_2023_ami" {
  description = "Amazon Linux 2023 AMI ID"
  type        = string
}

