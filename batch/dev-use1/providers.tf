provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  default_tags {
    tags = {
      Team = "Tech-Land-Manufacturing@enverus.com"
      Dataset = "land"
      SourceCode = "https://github.com/enverus-ea/land.llandman"
      Component =  "llandman"
      BusinessUnit = "ea"
      Product = "courthouse"
      Environment = "dev"
    }
  }
}

provider "awscc" {
  alias  = "use1"
  region = "us-east-1"
}
