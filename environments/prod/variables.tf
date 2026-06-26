variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name used for tagging"
  type        = string
}

# ── Phase 2: VPC ─────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "Existing VPC ID to import"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the existing VPC"
  type        = string
}

variable "igw_id" {
  description = "Existing Internet Gateway ID to import"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets keyed by AZ (e.g. 'us-east-1a')"
  type = map(object({
    id                = string
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets keyed by AZ. nat_gateway_az must match a key in var.nat_gateways."
  type = map(object({
    id                = string
    cidr_block        = string
    availability_zone = string
    nat_gateway_az    = string
  }))
  default = {}
}

variable "nat_gateways" {
  description = "Map of NAT gateways keyed by AZ. One entry = cost-efficient; one per AZ = HA."
  type = map(object({
    id        = string
    subnet_id = string
    eip_id    = string
  }))
  default = {}
}

# ── Phase 3: Security Groups ──────────────────────────────────────────────────

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

# ── Phase 5: S3 ───────────────────────────────────────────────────────────────

variable "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail logs S3 bucket"
  type        = string
}

variable "cloudtrail_trail_name" {
  description = "Name of the CloudTrail trail that writes to the CloudTrail logs bucket"
  type        = string
  default     = "management-events"
}
