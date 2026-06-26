variable "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail logs S3 bucket"
  type        = string
}

variable "cloudtrail_trail_name" {
  description = "Name of the CloudTrail trail that writes to this bucket"
  type        = string
  default     = "management-events"
}

variable "log_retention_days" {
  description = "Days before CloudTrail log objects expire"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
