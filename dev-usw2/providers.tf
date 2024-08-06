provider "aws" {
  alias = "usw2"
  region = "us-west-2"

  default_tags {
    tags = {
      StackName   = "Document-Processing"
      Environment = "Development"
      Owner       = "Ops"
    }
  }
}
