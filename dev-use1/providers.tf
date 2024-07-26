provider "aws" {
  alias = "use1"
  assume_role {
    role_arn = var.IAM_ROLE_ARN
  }
  region = "us-east-1"
}

# provider "aws" {
#   alias   = "use1"
#   region  = "us-east-1"
#   profile = "dev-assumed-role"
# }
