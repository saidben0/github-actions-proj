terraform {
  required_version = "~> 1.9.2"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.acc]
      version               = "~> 5.60.0"
    }

    awscc = {
      source                = "hashicorp/awscc"
      configuration_aliases = [awscc.acc]
      version               = "1.12.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
