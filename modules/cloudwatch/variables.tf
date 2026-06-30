variable "trail_name" {
  description = "CloudTrail trail name"
  type        = string
  default     = "management-events"
}

variable "cloudtrail_s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "log_retention_days" {
  description = "Retention period in days for yt-auto-uploader CloudWatch log groups"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
