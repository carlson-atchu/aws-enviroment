output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "Map of AZ → public subnet ID"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map of AZ → private subnet ID"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "nat_gateway_ids" {
  description = "Map of AZ → NAT gateway ID"
  value       = { for k, v in aws_nat_gateway.main : k => v.id }
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of AZ → private route table ID"
  value       = { for k, v in aws_route_table.private : k => v.id }
}
