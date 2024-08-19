provider "aws" {
  alias  = "usw2"
  region = "us-west-2"

  default_tags {
    tags = {
      StackName   = "Land.Llandman"
      Environment = "Development"
      Owner       = "Ops"
    }
  }
}
