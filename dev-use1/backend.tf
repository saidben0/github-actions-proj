terraform {
  backend "s3" {
    bucket = "di-dev-terraform"
    key    = "dev/llandman/terraform.tfstate"
    region = "us-east-1"
  }
}
