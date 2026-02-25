output "master_uploads_bucket_name" {
  description = "S3 bucket for admin master uploads."
  value       = module.master_bucket.bucket_id
}

output "hls_outputs_bucket_name" {
  description = "S3 bucket for HLS outputs."
  value       = module.hls_bucket.bucket_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront_hls.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain used by app playback URLs."
  value       = module.cloudfront_hls.domain_name
}

output "cloudfront_key_group_id" {
  description = "CloudFront key group ID configured as trusted key group."
  value       = module.cloudfront_hls.key_group_id
}

output "cloudfront_public_key_id" {
  description = "CloudFront public key ID for signing cookies."
  value       = module.cloudfront_hls.public_key_id
}

output "cloudfront_key_pair_id" {
  description = "Alias of CloudFront public key ID used in CloudFront-Key-Pair-Id cookie."
  value       = module.cloudfront_hls.public_key_id
}

output "mediaconvert_role_arn" {
  description = "MediaConvert service role ARN for Rails CreateJob calls."
  value       = module.iam_roles.mediaconvert_role_arn
}

output "rails_app_policy_arn" {
  description = "IAM policy ARN to attach to Rails runtime role."
  value       = module.iam_roles.rails_app_policy_arn
}

output "cloudfront_private_key_secret_arn" {
  description = "Secrets Manager ARN containing CloudFront private key."
  value       = module.cloudfront_private_key_secret.secret_arn
}

output "cloudfront_private_key_secret_name" {
  description = "Secrets Manager name containing CloudFront private key."
  value       = module.cloudfront_private_key_secret.secret_name
}

output "mediaconvert_endpoint_url" {
  description = "Optional explicit MediaConvert endpoint URL for Rails configuration."
  value       = module.mediaconvert.endpoint_url
}

output "rails_env_vars" {
  description = "Direct mapping of Terraform outputs to Rails env vars."
  value = {
    AWS_REGION                        = var.aws_region
    S3_MASTER_BUCKET                  = module.master_bucket.bucket_id
    S3_HLS_BUCKET                     = module.hls_bucket.bucket_id
    CLOUDFRONT_DOMAIN                 = module.cloudfront_hls.domain_name
    CLOUDFRONT_KEY_PAIR_ID            = module.cloudfront_hls.public_key_id
    CLOUDFRONT_PRIVATE_KEY_SECRET_ARN = module.cloudfront_private_key_secret.secret_arn
    MEDIACONVERT_ROLE_ARN             = module.iam_roles.mediaconvert_role_arn
  }
}
