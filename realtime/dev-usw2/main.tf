module "dev-usw2" {
  source                   = "../module"
  python_version           = var.python_version
  lambda_role_name         = var.lambda_role_name
  lambda_layer_version_arn = var.lambda_layer_version_arn
  inputs_bucket_name       = var.inputs_bucket_name
  env                      = var.env
  tags                     = var.tags

  providers = {
    aws.acc   = aws.usw2
    awscc.acc = awscc.usw2
  }
}
