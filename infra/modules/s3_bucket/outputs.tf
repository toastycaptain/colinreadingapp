output "bucket_id" {
  description = "Bucket ID/name."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name used by CloudFront origin."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
