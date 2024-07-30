terraform {
  backend "s3" {
    bucket         = "enverus-tfstates"
    key            = "dev/use1/tfstate"
    region         = "us-east-1"
    # dynamodb_table = "TerraformStateLocking"
  }
  # backend "local" {}
  # required_version = "~> 1.0"
}
