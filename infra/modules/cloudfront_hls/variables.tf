variable "name_prefix" {
  description = "Prefix used to name CloudFront resources."
  type        = string
}

variable "hls_bucket_regional_domain_name" {
  description = "Regional domain name for the HLS output S3 bucket."
  type        = string
}

variable "cloudfront_public_key_pem" {
  description = "PEM-encoded CloudFront public key content."
  type        = string
  sensitive   = true
}

variable "aliases" {
  description = "Optional alternate domain names for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN in us-east-1. Required when aliases are set."
  type        = string
  default     = null

  validation {
    condition     = length(var.aliases) == 0 || var.acm_certificate_arn != null
    error_message = "acm_certificate_arn is required when aliases are configured."
  }
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version when using ACM cert."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for creating alias records."
  type        = string
  default     = null
}

variable "hls_min_ttl" {
  description = "Minimum TTL for HLS cache policy."
  type        = number
  default     = 0
}

variable "hls_default_ttl" {
  description = "Default TTL for HLS cache policy."
  type        = number
  default     = 60
}

variable "hls_max_ttl" {
  description = "Maximum TTL for HLS cache policy."
  type        = number
  default     = 86400
}

variable "tags" {
  description = "Tags to apply to CloudFront resources."
  type        = map(string)
  default     = {}
}
