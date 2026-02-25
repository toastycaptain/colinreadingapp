output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "key_group_id" {
  description = "CloudFront key group ID used for trusted key groups."
  value       = aws_cloudfront_key_group.this.id
}

output "public_key_id" {
  description = "CloudFront public key ID (used as Key Pair ID in signed cookies)."
  value       = aws_cloudfront_public_key.this.id
}
