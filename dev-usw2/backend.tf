terraform {
  backend "s3" {
    bucket = "enverus-tfstates-0823"
    key    = "dev/usw2/tfstate"
    region = "us-east-1"
  }
}
