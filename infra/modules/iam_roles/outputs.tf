output "mediaconvert_role_arn" {
  description = "IAM role ARN used by MediaConvert jobs."
  value       = aws_iam_role.mediaconvert_service.arn
}

output "mediaconvert_role_name" {
  description = "IAM role name used by MediaConvert jobs."
  value       = aws_iam_role.mediaconvert_service.name
}

output "rails_app_policy_arn" {
  description = "Managed IAM policy ARN for Rails app AWS access."
  value       = aws_iam_policy.rails_app.arn
}
