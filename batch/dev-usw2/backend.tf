terraform {
  backend "s3" {
    # bucket = "di-dev-terraform"
    bucket = "enverus-tfstates-0823" # for testing in proserve shared acc
    key    = "staging/llandman/terraform.batch.tfstate"
    region = "us-west-2"
  }
}
