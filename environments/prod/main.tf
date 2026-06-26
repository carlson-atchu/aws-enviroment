terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Uncomment after Phase 1 (global/s3-backend) is applied and you have a bucket
  # backend "s3" {
  #   bucket         = "YOUR-STATE-BUCKET-NAME"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# ── Phase 2: VPC ─────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  vpc_id          = var.vpc_id
  cidr_block      = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  igw_id          = var.igw_id
  nat_gateways    = var.nat_gateways
  tags            = local.common_tags
}

# ── Phase 3: Security Groups ──────────────────────────────────────────────────
module "security_groups" {
  source         = "../../modules/security_groups"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = var.vpc_cidr_block
  app_port       = var.app_port
  db_port        = var.db_port
  tags           = local.common_tags
}

# ── Phase 4: IAM ──────────────────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"
  tags   = local.common_tags
}

# ── Phase 5: S3 ───────────────────────────────────────────────────────────────
module "s3" {
  source                 = "../../modules/s3"
  cloudtrail_bucket_name = var.cloudtrail_bucket_name
  cloudtrail_trail_name  = var.cloudtrail_trail_name
  tags                   = local.common_tags
}

# ── Phase 6: EC2 ──────────────────────────────────────────────────────────────
module "ec2" {
  source                = "../../modules/ec2"
  environment           = var.environment
  subnet_id             = module.vpc.public_subnet_ids["us-east-1a"]
  app_sg_id             = module.security_groups.app_sg_id
  instance_profile_name = module.iam.aws_organizations_instance_profile_name
  tags                  = local.common_tags
}

# ── Phase 7: RDS ──────────────────────────────────────────────────────────────
# module "rds" {
#   source             = "../../modules/rds"
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   tags               = local.common_tags
# }

# ── Phase 8: ALB ──────────────────────────────────────────────────────────────
# module "alb" {
#   source            = "../../modules/alb"
#   vpc_id            = module.vpc.vpc_id
#   public_subnet_ids = module.vpc.public_subnet_ids
#   tags              = local.common_tags
# }

# ── Phase 9: Route53 ──────────────────────────────────────────────────────────
# module "route53" {
#   source = "../../modules/route53"
#   tags   = local.common_tags
# }

# ── Phase 10: CloudWatch ──────────────────────────────────────────────────────
# module "cloudwatch" {
#   source = "../../modules/cloudwatch"
#   tags   = local.common_tags
# }
