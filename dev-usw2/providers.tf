provider "aws" {
  alias  = "usw2"
  region = "us-west-2"

  default_tags {
    tags = {
      StackName   = "Documents-Processing"
      Environment = "Development"
      Owner       = "Ops"
    }
  }
}
