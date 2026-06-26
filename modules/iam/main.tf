data "aws_caller_identity" "current" {}

# ── Managed Policies ──────────────────────────────────────────────────────────

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "describe_organization" {
  #checkov:skip=CKV_AWS_289:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_290:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_355:sso:* and identitystore:* wildcards required for Identity Center management
  name = "DescribeOrganization"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sso:*",
        "identitystore:*",
        "organizations:DescribeOrganization",
        "organizations:ListAccounts"
      ]
      Resource = "*"
    }]
  })

  tags = var.tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "terraform_identity_center_admin" {
  #checkov:skip=CKV_AWS_289:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_290:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_355:sso:* and identitystore:* wildcards required for Identity Center management
  name = "terraform-identity-center-admin"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateS3Only"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::terraform-pr-st",
          "arn:aws:s3:::terraform-pr-st/*"
        ]
      },
      {
        Sid    = "AllowIAMForIdentityCenterProvisioning"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:GetPolicy",
          "iam:GetSAMLProvider",
          "iam:ListSAMLProviders"
        ]
        Resource = "*"
      },
      {
        Sid    = "IdentityCenterAdmin"
        Effect = "Allow"
        Action = [
          "sso:*",
          "identitystore:*",
          "organizations:ListAccounts",
          "organizations:DescribeOrganization",
          "organizations:ListRoots",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListAccountsForParent"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# ── terraform-identity-center-admin role ─────────────────────────────────────

resource "aws_iam_role" "terraform_identity_center_admin" {
  name        = "terraform-identity-center-admin"
  description = "Role for Terraform to manage Identity Center resources"
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "terraform_identity_center_admin" {
  #checkov:skip=CKV_AWS_289:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_290:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_355:sso:* and identitystore:* wildcards required for Identity Center management
  name = "terraform-identity-center-admin"
  role = aws_iam_role.terraform_identity_center_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sso:*",
        "identitystore:*",
        "organizations:DescribeOrganization",
        "organizations:ListAccounts"
      ]
      Resource = "*"
    }]
  })
}

# Denies all actions for sessions issued before the configured cutoff timestamp.
# Update var.revoke_sessions_before when rotating credentials.
resource "aws_iam_role_policy" "revoke_older_sessions" {
  name = "AWSRevokeOlderSessions"
  role = aws_iam_role.terraform_identity_center_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = ["*"]
      Resource = ["*"]
      Condition = {
        DateLessThan = {
          "aws:TokenIssueTime" = var.revoke_sessions_before
        }
      }
    }]
  })
}

# ── aws-organizations EC2 instance role ──────────────────────────────────────

resource "aws_iam_role" "aws_organizations" {
  name        = "aws-organizations"
  description = "EC2 instance role for Organizations and SSO read access"
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "aws_organizations_describe" {
  #checkov:skip=CKV_AWS_289:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_290:sso:* and identitystore:* wildcards required for Identity Center management
  #checkov:skip=CKV_AWS_355:sso:* and identitystore:* wildcards required for Identity Center management
  name = "DescribeOrganization"
  role = aws_iam_role.aws_organizations.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sso:*",
        "identitystore:*",
        "organizations:DescribeOrganization",
        "organizations:ListAccounts"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "aws_organizations" {
  name = "aws-organizations"
  role = aws_iam_role.aws_organizations.name

  tags = var.tags
}
