terraform {
  backend "s3" {
    bucket         = "enverus-tfstates"
    key            = "dev/usw2/tfstate"
    region         = "us-west-2"
  }
}
