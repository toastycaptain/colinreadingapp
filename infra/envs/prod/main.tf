terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  cloudfront_aliases = var.domain_name == null ? [] : [var.domain_name]
  master_bucket_name = coalesce(var.master_uploads_bucket_name, "${var.project_name}-master-uploads-${var.environment}")
  hls_outputs_name   = coalesce(var.hls_outputs_bucket_name, "${var.project_name}-hls-outputs-${var.environment}")
  cloudfront_secret  = coalesce(var.cloudfront_private_key_secret_name, "${var.project_name}/${var.environment}/cloudfront_private_key")
  default_resource_tag = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  tags = merge(local.default_resource_tag, var.tags)
}

module "master_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name                = local.master_bucket_name
  force_destroy              = var.master_force_destroy
  versioning_enabled         = true
  transition_to_glacier_days = var.master_transition_to_glacier_days
  tags                       = local.tags

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT", "POST", "GET", "HEAD"]
      allowed_origins = var.admin_allowed_origins
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}

module "hls_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name                = local.hls_outputs_name
  force_destroy              = var.hls_force_destroy
  versioning_enabled         = true
  transition_to_glacier_days = null
  tags                       = local.tags
}

module "cloudfront_private_key_secret" {
  source = "../../modules/secrets"

  secret_name             = local.cloudfront_secret
  description             = "CloudFront private key for ${local.name_prefix} signed cookies"
  manage_secret_value     = var.manage_cloudfront_private_key_secret_value
  secret_string           = var.cloudfront_private_key_pem
  recovery_window_in_days = 7
  tags                    = local.tags
}

module "cloudfront_hls" {
  source = "../../modules/cloudfront_hls"

  name_prefix                     = local.name_prefix
  hls_bucket_regional_domain_name = module.hls_bucket.bucket_regional_domain_name
  cloudfront_public_key_pem       = var.cloudfront_public_key_pem
  aliases                         = local.cloudfront_aliases
  acm_certificate_arn             = var.acm_certificate_arn
  route53_zone_id                 = var.route53_zone_id
  minimum_protocol_version        = "TLSv1.2_2021"
  price_class                     = var.price_class
  hls_min_ttl                     = var.hls_min_ttl
  hls_default_ttl                 = var.hls_default_ttl
  hls_max_ttl                     = var.hls_max_ttl
  tags                            = local.tags
}

data "aws_iam_policy_document" "hls_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontReadFromOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = [
      "${module.hls_bucket.bucket_arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront_hls.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "hls_bucket" {
  bucket = module.hls_bucket.bucket_id
  policy = data.aws_iam_policy_document.hls_bucket_policy.json
}

module "iam_roles" {
  source = "../../modules/iam_roles"

  name_prefix                         = local.name_prefix
  master_bucket_arn                   = module.master_bucket.bucket_arn
  hls_bucket_arn                      = module.hls_bucket.bucket_arn
  cloudfront_private_key_secret_arn   = module.cloudfront_private_key_secret.secret_arn
  include_cloudwatch_logs_permissions = var.include_mediaconvert_log_permissions
  tags                                = local.tags
}

module "mediaconvert" {
  source = "../../modules/mediaconvert"

  endpoint_url      = var.mediaconvert_endpoint_url
  job_template_name = var.mediaconvert_job_template_name
}
