variable "vpc_id" {
  description = "ID of the existing VPC (used only as an import reference)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "igw_id" {
  description = "ID of the existing Internet Gateway (used only as an import reference)"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets keyed by AZ name"
  type = map(object({
    id                = string
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets keyed by AZ name. nat_gateway_az must match a key in var.nat_gateways."
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
