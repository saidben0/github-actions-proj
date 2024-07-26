module "dev-use1" {
  source = "../module"
  region = "use1"
  providers = {
    aws.acc = aws.use1
  }
}
