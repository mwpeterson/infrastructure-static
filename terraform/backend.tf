terraform {
  backend "s3" {
    bucket = "gatewaychurch-static-terraform-state-dev"
    key    = "pinkimpact-static/dev"
    encrypt = "1"
    acl = "private"
    region = "us-west-2"
    lock_table = "gatewaychurch-static-terraform-lock-dev"
  }
}
