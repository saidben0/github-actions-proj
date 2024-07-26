terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.acc]
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
