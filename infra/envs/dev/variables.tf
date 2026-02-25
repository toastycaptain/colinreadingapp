variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
}

variable "project_name" {
  description = "Project prefix for resource names."
  type        = string
  default     = "storytime"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Optional custom CloudFront domain alias (e.g. cdn.example.com)."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID used when domain_name is set."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for custom domain alias."
  type        = string
  default     = null

  validation {
    condition     = var.domain_name == null || var.acm_certificate_arn != null
    error_message = "acm_certificate_arn is required when domain_name is set."
  }
}

variable "admin_allowed_origins" {
  description = "Allowed origins for browser-based direct uploads to master bucket."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "cloudfront_public_key_pem" {
  description = "PEM public key used to create CloudFront public key resource."
  type        = string
  sensitive   = true
}

variable "cloudfront_private_key_secret_name" {
  description = "Secrets Manager name for CloudFront private signing key."
  type        = string
  default     = null
}

variable "manage_cloudfront_private_key_secret_value" {
  description = "Set true in dev to let Terraform manage the secret payload."
  type        = bool
  default     = true
}

variable "cloudfront_private_key_pem" {
  description = "Optional private key PEM. Required if manage_cloudfront_private_key_secret_value=true."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.manage_cloudfront_private_key_secret_value == false || var.cloudfront_private_key_pem != null
    error_message = "cloudfront_private_key_pem must be set when manage_cloudfront_private_key_secret_value is true."
  }
}

variable "master_uploads_bucket_name" {
  description = "Optional override for master uploads bucket name."
  type        = string
  default     = null
}

variable "hls_outputs_bucket_name" {
  description = "Optional override for HLS outputs bucket name."
  type        = string
  default     = null
}

variable "master_force_destroy" {
  description = "Allow destroy on non-empty master uploads bucket."
  type        = bool
  default     = true
}

variable "hls_force_destroy" {
  description = "Allow destroy on non-empty HLS outputs bucket."
  type        = bool
  default     = true
}

variable "master_transition_to_glacier_days" {
  description = "Optional lifecycle transition for master uploads bucket."
  type        = number
  default     = null
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "hls_min_ttl" {
  description = "CloudFront cache policy min TTL for HLS."
  type        = number
  default     = 0
}

variable "hls_default_ttl" {
  description = "CloudFront cache policy default TTL for HLS."
  type        = number
  default     = 60
}

variable "hls_max_ttl" {
  description = "CloudFront cache policy max TTL for HLS."
  type        = number
  default     = 86400
}

variable "include_mediaconvert_log_permissions" {
  description = "Include CloudWatch Logs permissions in MediaConvert role policy."
  type        = bool
  default     = true
}

variable "mediaconvert_endpoint_url" {
  description = "Optional fixed MediaConvert endpoint URL for Rails configuration."
  type        = string
  default     = null
}

variable "mediaconvert_job_template_name" {
  description = "Optional shared MediaConvert job template name."
  type        = string
  default     = null
}
