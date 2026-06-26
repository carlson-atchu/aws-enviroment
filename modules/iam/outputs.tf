output "terraform_identity_center_admin_role_arn" {
  description = "ARN of the terraform-identity-center-admin role"
  value       = aws_iam_role.terraform_identity_center_admin.arn
}

output "aws_organizations_role_arn" {
  description = "ARN of the aws-organizations EC2 instance role"
  value       = aws_iam_role.aws_organizations.arn
}

output "aws_organizations_instance_profile_name" {
  description = "Name of the aws-organizations instance profile"
  value       = aws_iam_instance_profile.aws_organizations.name
}

output "aws_organizations_instance_profile_arn" {
  description = "ARN of the aws-organizations instance profile"
  value       = aws_iam_instance_profile.aws_organizations.arn
}
