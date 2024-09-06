terraform {
  backend "s3" {
    bucket = "di-dev-terraform"
    prefix = "dev/llandman"
    # bucket = "enverus-tfstates-0823" # for testing in proserve shared acc
    key    = "terraform.tfstate"
    # key    = "dev/use1/tfstate" # for testing in proserve shared acc
    region = "us-east-1"
  }
}
