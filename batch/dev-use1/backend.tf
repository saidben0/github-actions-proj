terraform {
  backend "s3" {
    bucket = "di-dev-terraform"
    # bucket = "enverus-tfstates-0823" # for testing in proserve shared acc
    key    = "dev/llandman/terraform.batch.tfstate"
    region = "us-east-1"
  }
}
