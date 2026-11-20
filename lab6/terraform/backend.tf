terraform {
  backend "s3" {
    bucket       = "acs730-tfstate-770670908864"
    key          = "lab6/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
