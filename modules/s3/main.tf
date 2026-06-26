data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── CloudTrail logs bucket ────────────────────────────────────────────────────

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "cloudtrail_logs" {
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for a CloudTrail logs bucket
  #checkov:skip=CKV2_AWS_62:Event notifications not required for a CloudTrail logs bucket
  #checkov:skip=CKV_AWS_18:No dedicated access-log bucket for the CloudTrail logs bucket
  #checkov:skip=CKV_AWS_145:CloudTrail logs bucket intentionally uses SSE-S3; no CMK required for this log bucket
  bucket = var.cloudtrail_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

#tfsec:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck20150319-e38469ee-98b2-47b8-ae01-82419a60c286"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket_name}"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_trail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite20150319-6c17b9dc-c70f-43b3-94c3-178c4af0ff14"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_trail_name}"
          }
        }
      }
    ]
  })
}
