data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "vpc-${var.tags["Environment"]}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "igw-${var.tags["Environment"]}"
  })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true #checkov:skip=CKV_AWS_130:Public subnets intentionally assign public IPs

  tags = merge(var.tags, {
    Name = "subnet-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "subnet-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  for_each = var.nat_gateways
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "eip-nat-${each.key}"
  })
}

resource "aws_nat_gateway" "main" {
  for_each      = var.nat_gateways
  subnet_id     = each.value.subnet_id
  allocation_id = aws_eip.nat[each.key].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "nat-${each.key}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "rtb-public"
    Tier = "public"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.nat_gateways
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = merge(var.tags, {
    Name = "rtb-private-${each.key}"
    Tier = "private"
  })
}

# nat_gateway_az on each private subnet controls which private route table it uses.
resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value.nat_gateway_az].id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "default-sg-locked"
  })
}

resource "aws_kms_key" "flow_logs" {
  description             = "CMK for VPC flow logs CloudWatch log group"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAdminAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs-${var.tags["Environment"]}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "vpc-flow-logs-${var.tags["Environment"]}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = [
        aws_cloudwatch_log_group.flow_logs.arn,
        "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      ]
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = var.tags
}
