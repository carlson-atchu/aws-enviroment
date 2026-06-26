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

# ── Phase 4: IAM ──────────────────────────────────────────────────────────────
output "terraform_identity_center_admin_role_arn" {
  description = "ARN of the terraform-identity-center-admin role"
  value       = module.iam.terraform_identity_center_admin_role_arn
}

output "aws_organizations_instance_profile_name" {
  description = "Name of the aws-organizations instance profile"
  value       = module.iam.aws_organizations_instance_profile_name
}

# ── Phase 3: Security Groups ──────────────────────────────────────────────────
output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.security_groups.alb_sg_id
}

output "app_sg_id" {
  description = "App security group ID"
  value       = module.security_groups.app_sg_id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.security_groups.rds_sg_id
}
