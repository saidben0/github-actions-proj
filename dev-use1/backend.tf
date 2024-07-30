terraform {
  backend "s3" {
    bucket         = "enverus-tfstates"
    key            = "dev/use1/tfstate"
    region         = "us-east-1"
  }
}
