output "jenkins_public_ip" {
  value = module.webserver.instance_public_ips["jenkins"]
}

output "docker_public_ip" {
  value = module.webserver.instance_public_ips["docker"]
}

output "free_public_ip" {
  value = module.webserver.instance_public_ips["free"]
}

