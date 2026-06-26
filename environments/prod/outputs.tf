# ── Phase 2: VPC ─────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Map of AZ → public subnet ID"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of AZ → private subnet ID"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "Map of AZ → NAT gateway ID"
  value       = module.vpc.nat_gateway_ids
}
