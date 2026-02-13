output "instance_public_ips" {
  description = "Public IPs of all EC2s"
  value = { for name, instance in aws_instance.servers : name => instance.public_ip }
}

