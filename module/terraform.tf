terraform {
  required_version = "~> 1.9.2"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.acc]
      version               = "~> 5.60.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
  }
}
