# AWS region
variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet CIDRs
variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets: Jenkins, Docker, Free"
  type        = list(string)
  default = [
    "10.0.1.0/24", # Jenkins subnet
    "10.0.2.0/24", # Docker subnet
    "10.0.3.0/24"  # Free subnet
  ]
}

# EC2 instance types
variable "instance_types" {
  description = "Map of instance types per EC2"
  type        = map(string)
  default = {
    jenkins = "t2.large"
    docker  = "t2.large"
    free    = "t2.micro"
  }
}

# Key pair
variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

# AMI
variable "amazon_linux_2023_ami" {
  description = "Amazon Linux 2023 AMI ID"
  type        = string
  default     = "ami-0532be01f26a3de55"
}

# Root volume size in GiB
variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 40
}

# Security group CIDRs
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to access SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed to access Jenkins HTTP (8080)"
  type        = string
  default     = "0.0.0.0/0"
}

