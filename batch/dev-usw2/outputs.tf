output "current_region" {
  value = module.dev-usw2.current_region
}

output "current_account_id" {
  value = module.dev-usw2.current_account_id
}

output "current_caller_arn" {
  value = module.dev-usw2.current_caller_arn
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
