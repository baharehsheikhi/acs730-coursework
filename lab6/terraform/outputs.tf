output "instance_ids" {
  description = "IDs of the Lab 6 web instances"
  value       = aws_instance.web[*].id
}

output "public_ips" {
  description = "Public IP addresses of the web instances"
  value       = aws_instance.web[*].public_ip
}

output "security_group_id" {
  description = "Lab 6 web security group ID"
  value       = aws_security_group.web.id
}
