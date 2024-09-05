output "current_region" {
  value = module.dev-use1.current_region
}

output "current_account_id" {
  value = module.dev-use1.current_account_id
}

output "current_caller_arn" {
  value = module.dev-use1.current_caller_arn
}

output "prompt_id" {
  value = module.dev-use1.prompt_id
}

output "prompt_name" {
  value = module.dev-use1.prompt_name
}

output "prompt_arn" {
  value = module.dev-use1.prompt_arn
}

# output "prompt_version" {
#   value = module.dev-use1.prompt_version
# }

output "lambda_role_name" {
  value = module.dev-use1.lambda_role_name
}

output "lambda_role_arn" {
  value = module.dev-use1.lambda_role_arn
}

# output "lambda_policy_name" {
#   value = module.dev-use1.lambda_policy_name
# }

# output "bedrock_prompt_id" {
#   value = awscc_bedrock_prompt.this.prompt_id
# }

# output "bedrock_prompt_name" {
#   value = awscc_bedrock_prompt.this.name
# }

# output "bucket_name" {
#   value = module.dev-use1.bucket_name
# }