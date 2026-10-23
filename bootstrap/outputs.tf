output "state_bucket_name" {
  description = "s3 backend"
  value       = aws_s3_bucket.state.bucket
}
output "github_ci_role_arn" {
  description = "Role attribute"
  value       = aws_iam_role.github_ci.arn
}