data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── CloudTrail ────────────────────────────────────────────────────────────────

#tfsec:ignore:aws-cloudtrail-enable-log-validation
#tfsec:ignore:aws-cloudtrail-enable-at-rest-encryption
#tfsec:ignore:aws-cloudtrail-ensure-cloudwatch-integration
resource "aws_cloudtrail" "management_events" {
  #checkov:skip=CKV_AWS_36:Log file validation disabled; low-risk single-account trail
  #checkov:skip=CKV_AWS_35:CloudWatch Logs not wired; alarm-based monitoring used instead
  #checkov:skip=CKV2_AWS_10:CloudWatch Logs not wired; alarm-based monitoring used instead
  #checkov:skip=CKV_AWS_252:No SNS notification; CloudWatch alarm-based alerting used instead
  #checkov:skip=CKV_AWS_213:Trail at-rest encryption not required for single-account management events
  name                          = var.trail_name
  s3_bucket_name                = var.cloudtrail_s3_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = false

  advanced_event_selector {
    name = "Management events selector"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  tags = var.tags
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "yt_upload_failures" {
  #checkov:skip=CKV_AWS_119:No SNS topic; alarm is monitored manually
  alarm_name          = "yt-auto-uploader-upload-failures"
  alarm_description   = "Alert when upload handler fails 2+ times in a 6-hour window"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  period              = 21600
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = "yt-auto-uploader-upload-handler"
  }

  tags = var.tags
}

# ── yt-auto-uploader CloudWatch Log Groups ────────────────────────────────────
# Import existing log groups and enforce retention — functions are managed
# outside Terraform (separate deployment pipeline).

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "yt_clip_fetcher" {
  #checkov:skip=CKV_AWS_158:Lambda execution logs; CMK encryption is overkill
  #checkov:skip=CKV_AWS_66:30-day retention is sufficient for Lambda execution logs
  #checkov:skip=CKV_AWS_338:30-day retention is sufficient for Lambda execution logs
  name              = "/aws/lambda/yt-auto-uploader-clip-fetcher"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "yt_upload_handler" {
  #checkov:skip=CKV_AWS_158:Lambda execution logs; CMK encryption is overkill
  #checkov:skip=CKV_AWS_66:30-day retention is sufficient for Lambda execution logs
  #checkov:skip=CKV_AWS_338:30-day retention is sufficient for Lambda execution logs
  name              = "/aws/lambda/yt-auto-uploader-upload-handler"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "yt_video_generator" {
  #checkov:skip=CKV_AWS_158:Lambda execution logs; CMK encryption is overkill
  #checkov:skip=CKV_AWS_66:30-day retention is sufficient for Lambda execution logs
  #checkov:skip=CKV_AWS_338:30-day retention is sufficient for Lambda execution logs
  name              = "/aws/lambda/yt-auto-uploader-video-generator"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ── yt-auto-uploader EventBridge Schedules ────────────────────────────────────
# Functions are unmanaged (separate pipeline); import rules/targets only.
# Lambda permissions already exist in AWS and are left unmanaged.

resource "aws_cloudwatch_event_rule" "yt_clip_fetch" {
  name                = "yt-auto-uploader-clip-fetch"
  description         = "Fetch 2 fresh nature clips from Pexels every 12 hours"
  schedule_expression = "rate(12 hours)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_rule" "yt_upload_schedule" {
  name                = "yt-auto-uploader-schedule"
  description         = "Trigger YouTube uploader every 6 hours"
  schedule_expression = "rate(6 hours)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "yt_clip_fetch" {
  rule      = aws_cloudwatch_event_rule.yt_clip_fetch.name
  target_id = "ClipFetcher"
  arn       = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:yt-auto-uploader-clip-fetcher"
}

resource "aws_cloudwatch_event_target" "yt_upload_schedule" {
  rule      = aws_cloudwatch_event_rule.yt_upload_schedule.name
  target_id = "UploadHandler"
  arn       = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:yt-auto-uploader-upload-handler"
}
