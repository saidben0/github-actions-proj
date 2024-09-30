output "current_region" {
  value = module.dev-use1.current_region
}

output "current_account_id" {
  value = module.dev-use1.current_account_id
}

output "current_caller_arn" {
  value = module.dev-use1.current_caller_arn
}

output "bedrock_prompts" {
  value = module.dev-use1.bedrock_prompts
}


output "lambda_role_name" {
  value = module.dev-use1.lambda_role_name
}

output "lambda_role_arn" {
  value = module.dev-use1.lambda_role_arn
}

output "lambda_layer_version_arn" {
  value = var.lambda_layer_version_arn
}

output "dynamodb_table_name" {
  value = module.dev-use1.dynamodb_table_name
}
