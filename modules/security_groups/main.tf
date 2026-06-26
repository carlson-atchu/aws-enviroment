resource "aws_security_group" "alb" {
  name        = "alb-${var.tags["Environment"]}"
  description = "Internet-facing ALB - allows HTTP and HTTPS from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #checkov:skip=CKV_AWS_260:ALB must accept public HTTP to redirect to HTTPS
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALB to reach app instances"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(var.tags, {
    Name = "alb-${var.tags["Environment"]}"
    Tier = "public"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name        = "app-${var.tags["Environment"]}"
  description = "App instances - allows traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description     = "Allow app to reach database"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  egress {
    description = "Allow app to reach internet (package updates, external APIs)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "app-${var.tags["Environment"]}"
    Tier = "app"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-${var.tags["Environment"]}"
  description = "RDS - allows database traffic from app instances only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "rds-${var.tags["Environment"]}"
    Tier = "data"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Separate ingress rule avoids the circular dependency between app-sg and rds-sg
resource "aws_security_group_rule" "rds_ingress_from_app" {
  type                     = "ingress"
  description              = "Database port from app instances"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.app.id
}
