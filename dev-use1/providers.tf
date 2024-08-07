provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  default_tags {
    tags = {
      StackName   = "Documents-Processing"
      Environment = "Development"
      Owner       = "Ops"
    }
  }
}
