output "current_region" {
  value = data.aws_region.current.name
}

output "current_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "current_caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "lambda_role_name" {
  value = aws_iam_role.queue_processing_lambda_role.name
}

output "lambda_IAM_ROLE_ARN_DEV" {
  value = aws_iam_role.queue_processing_lambda_role.arn
}

output "lambda_policy_name" {
  value = aws_iam_role_policy.queue_processing_lambda_policy.name
}

# output "bucket_name" {
#   value = aws_s3_bucket.this.id
# }
