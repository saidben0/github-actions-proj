output "current_region" {
  value = local.region
}

output "current_account_id" {
  value = local.account_id
}

output "current_caller_arn" {
  value = data.aws_caller_identity.this.arn
}

output "bedrock_prompts" {
  value = local.bedrock_prompts
}

output "bedrock_prompt_ids" {
  value = { for p in awscc_bedrock_prompt.this : p.id => p.id }
}

# output "prompt_id" {
#   value = awscc_bedrock_prompt.this[*].prompt_id
# }

# output "prompt_name" {
#   value = awscc_bedrock_prompt.this[*].name
# }

# output "prompt_arn" {
#   value = awscc_bedrock_prompt.this[*].arn
# }

# output "prompt_version" {
#   value = awscc_bedrock_prompt_version.this.version
# }

output "lambda_role_name" {
  value = data.aws_iam_role.llandman_lambda_exec_role.name
}

output "lambda_role_arn" {
  value = data.aws_iam_role.llandman_lambda_exec_role.arn
}

# output "lambda_policy_name" {
#   value = aws_iam_role_policy.queue_processing_lambda_policy.name
# }

# output "kms_key_arn" {
#   value = data.aws_kms_key.this.arn
# }
