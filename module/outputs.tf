output "current_region" {
  value = local.region
}

output "current_account_id" {
  value = local.account_id
}

output "current_caller_arn" {
  value = data.aws_caller_identity.this.arn
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

# output "kms_key_arn" {
#   value = data.aws_kms_key.this.arn
# }
