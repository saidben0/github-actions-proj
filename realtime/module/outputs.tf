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
  value = { for p in awscc_bedrock_prompt.this : p.name => p.arn }
}

output "lambda_role_name" {
  value = data.aws_iam_role.llandman_lambda_exec_role.name
}

output "lambda_role_arn" {
  value = data.aws_iam_role.llandman_lambda_exec_role.arn
}

output "lambda_layer_version_arn" {
  value = var.lambda_layer_version_arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.model_outputs.name
}
