variable "environment" {
  description = "Environment name (used for resource naming)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the EC2 instance into"
  type        = string
}

variable "app_sg_id" {
  description = "Security group ID for the EC2 app instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "start_schedule" {
  description = "EventBridge cron expression to start the instance (UTC). Default = 7am US/Eastern."
  type        = string
  default     = "cron(0 11 * * ? *)"
}

variable "stop_schedule" {
  description = "EventBridge cron expression to stop the instance (UTC). Default = 7pm US/Eastern."
  type        = string
  default     = "cron(0 23 * * ? *)"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
