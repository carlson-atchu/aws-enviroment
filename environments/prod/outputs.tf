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

# ── Phase 6: EC2 ─────────────────────────────────────────────────────────────
output "instance_id" {
  description = "EC2 app instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 app instance"
  value       = module.ec2.instance_public_ip
}

output "scheduler_lambda_arn" {
  description = "ARN of the EC2 start/stop scheduler Lambda"
  value       = module.ec2.scheduler_lambda_arn
}

# ── Phase 10: CloudWatch ─────────────────────────────────────────────────────
output "cloudtrail_trail_arn" {
  description = "ARN of the management-events CloudTrail trail"
  value       = module.cloudwatch.cloudtrail_arn
}

output "yt_upload_failures_alarm_arn" {
  description = "ARN of the yt-auto-uploader upload failures CloudWatch alarm"
  value       = module.cloudwatch.yt_upload_failures_alarm_arn
}

# ── Phase 5: S3 ───────────────────────────────────────────────────────────────
output "cloudtrail_bucket_id" {
  description = "Name of the CloudTrail logs S3 bucket"
  value       = module.s3.cloudtrail_bucket_id
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail logs S3 bucket"
  value       = module.s3.cloudtrail_bucket_arn
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
