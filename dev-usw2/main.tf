module "dev-usw2" {
  source = "../module"
  region = "usw2"
  providers = {
    aws.acc = aws.usw2
  }
}
