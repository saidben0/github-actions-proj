terraform {
  backend "s3" {
    # bucket = "di-dev-terraform"
    bucket = "enverus-tfstates-0823" # for testing in proserve shared acc
    key    = "dev/usw2/llandman/terraform.tfstate"
    region = "us-east-1"
  }
}