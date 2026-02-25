variable "name_prefix" {
  description = "Prefix for IAM role/policy names."
  type        = string
}

variable "master_bucket_arn" {
  description = "ARN for the master uploads bucket."
  type        = string
}

variable "hls_bucket_arn" {
  description = "ARN for the HLS output bucket."
  type        = string
}

variable "cloudfront_private_key_secret_arn" {
  description = "ARN for the Secrets Manager secret storing CloudFront private key."
  type        = string
}

variable "include_cloudwatch_logs_permissions" {
  description = "Include CloudWatch Logs permissions in MediaConvert role policy."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to IAM resources where supported."
  type        = map(string)
  default     = {}
}
