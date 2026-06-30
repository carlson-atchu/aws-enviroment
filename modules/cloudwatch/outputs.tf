output "cloudtrail_arn" {
  description = "ARN of the management-events CloudTrail trail"
  value       = aws_cloudtrail.management_events.arn
}

output "yt_upload_failures_alarm_arn" {
  description = "ARN of the yt-auto-uploader upload failures CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.yt_upload_failures.arn
}
