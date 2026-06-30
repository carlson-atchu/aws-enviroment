data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── EC2 App Instance ──────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  #checkov:skip=CKV_AWS_88:Default VPC has no private subnets; public subnet required
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.app_sg_id]
  iam_instance_profile        = var.instance_profile_name
  ebs_optimized               = true
  monitoring                  = true
  associate_public_ip_address = true

  # Ignore AMI updates (most_recent picks newer AMIs on each plan) and
  # associate_public_ip_address (subnet auto-assign reflects false in state
  # even though the instance has a public IP).
  lifecycle {
    ignore_changes = [ami, associate_public_ip_address]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = "app-${var.environment}" })
}

# ── Lambda EC2 Scheduler ──────────────────────────────────────────────────────

data "archive_file" "scheduler" {
  type        = "zip"
  output_path = "${path.module}/lambda_scheduler.zip"
  source {
    content  = file("${path.module}/lambda_scheduler.py")
    filename = "lambda_scheduler.py"
  }
}

resource "aws_iam_role" "lambda_scheduler" {
  name = "ec2-scheduler-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "lambda_scheduler_ec2" {
  #checkov:skip=CKV_AWS_290:ec2:DescribeInstances requires Resource=* (AWS does not support resource-level for describe)
  #checkov:skip=CKV_AWS_355:ec2:DescribeInstances requires Resource=* (AWS does not support resource-level for describe)
  name = "ec2-start-stop"
  role = aws_iam_role.lambda_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:StartInstances", "ec2:StopInstances"]
        Resource = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.app.id}"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_scheduler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "lambda_scheduler" {
  #checkov:skip=CKV_AWS_158:Scheduler logs do not contain sensitive data; CMK encryption is overkill
  #checkov:skip=CKV_AWS_66:Scheduler logs do not contain sensitive data; CMK encryption is overkill
  #checkov:skip=CKV_AWS_338:Scheduler logs do not require 1-year retention; 30 days is sufficient
  name              = "/aws/lambda/ec2-scheduler"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_lambda_function" "scheduler" {
  #checkov:skip=CKV_AWS_117:Scheduler Lambda calls public EC2 API; VPC not required
  #checkov:skip=CKV_AWS_116:DLQ not required for a simple EC2 start/stop scheduler
  #checkov:skip=CKV_AWS_272:Code signing not required for an internal scheduler function
  #checkov:skip=CKV_AWS_115:Account concurrency limit is at AWS minimum (10); reserved concurrency not possible
  #checkov:skip=CKV_AWS_173:INSTANCE_ID env var is not a secret; KMS encryption of env vars is overkill
  function_name    = "ec2-scheduler"
  role             = aws_iam_role.lambda_scheduler.arn
  handler          = "lambda_scheduler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.scheduler.output_path
  source_code_hash = data.archive_file.scheduler.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.app.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_scheduler,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  tags = var.tags
}

# ── EventBridge Schedules ─────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "start" {
  name                = "ec2-start-schedule"
  description         = "Start app EC2 at 7am US/Eastern (11:00 UTC)"
  schedule_expression = var.start_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "stop" {
  name                = "ec2-stop-schedule"
  description         = "Stop app EC2 at 7pm US/Eastern (23:00 UTC)"
  schedule_expression = var.stop_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "start" {
  rule      = aws_cloudwatch_event_rule.start.name
  target_id = "StartEC2Instance"
  arn       = aws_lambda_function.scheduler.arn
  input     = jsonencode({ action = "start" })
}

resource "aws_cloudwatch_event_target" "stop" {
  rule      = aws_cloudwatch_event_rule.stop.name
  target_id = "StopEC2Instance"
  arn       = aws_lambda_function.scheduler.arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "start" {
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start.arn
}

resource "aws_lambda_permission" "stop" {
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop.arn
}

resource "aws_cloudwatch_event_rule" "weekend_stop" {
  name                = "ec2-weekend-stop"
  description         = "Stop app EC2 at midnight US/Eastern on Saturdays (00:01 UTC)"
  schedule_expression = var.weekend_stop_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "weekend_stop" {
  rule      = aws_cloudwatch_event_rule.weekend_stop.name
  target_id = "WeekendStop"
  arn       = aws_lambda_function.scheduler.arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "weekend_stop" {
  statement_id  = "AllowWeekendStopEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekend_stop.arn
}
