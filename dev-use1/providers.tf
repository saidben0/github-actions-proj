provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  default_tags {
    tags = {
      StackName   = "Land.Llandman"
      Environment = "Development"
      Owner       = "Ops"
    }
  }
}

provider "awscc" {
  alias  = "use1"
  region = "us-east-1"
}
