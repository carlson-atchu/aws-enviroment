variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block — used to scope ALB egress to app instances"
  type        = string
}

variable "app_port" {
  description = "Port the app instances listen on"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port (5432 = PostgreSQL, 3306 = MySQL)"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
