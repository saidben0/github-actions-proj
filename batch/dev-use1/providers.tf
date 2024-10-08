provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  default_tags {
    tags = {
      GitRepo = "Land.Llandman"
      Env     = "Dev"
      Owner   = "Ops"
    }
  }
}

provider "awscc" {
  alias  = "use1"
  region = "us-east-1"
}
