output "current_region" {
  value = module.dev-usw2.current_region
}

output "current_account_id" {
  value = module.dev-usw2.current_account_id
}

output "current_caller_arn" {
  value = module.dev-usw2.current_caller_arn
}

output "bedrock_prompts" {
  value = module.dev-usw2.bedrock_prompts
}


output "lambda_role_name" {
  value = module.dev-usw2.lambda_role_name
}

output "lambda_role_arn" {
  value = module.dev-usw2.lambda_role_arn
}

output "lambda_layer_version_arn" {
  value = var.lambda_layer_version_arn
}

output "aws_lambda_code_signing_config_arn" {
  value = module.dev-usw2.aws_lambda_code_signing_config_arn
}

output "dynamodb_table_name" {
  value = module.dev-usw2.dynamodb_table_name
}
