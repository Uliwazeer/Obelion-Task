output "vpc_id" {
  description = "Default VPC id"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Subnet ids in default VPC"
  value       = data.aws_subnets.default_vpc_subnets.ids
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.mysql.address
}

