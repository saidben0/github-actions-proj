provider "aws" {
  alias = "usw2"
  # assume_role {
  #   role_arn = var.IAM_ROLE_ARN
  # }
  region = "us-west-2"
}
