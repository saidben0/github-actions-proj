provider "aws" {
  alias  = "usw2"
  region = "us-west-2"

  default_tags {
    tags = {
      Team         = "Tech-Land-Manufacturing@enverus.com"
      Dataset      = "land"
      SourceCode   = "https://github.com/enverus-ea/land.llandman"
      Component    = "llandman"
      BusinessUnit = "ea"
      Product      = "courthouse"
      Environment  = "staging"
    }
  }
}

provider "awscc" {
  alias  = "usw2"
  region = "us-west-2"
}
