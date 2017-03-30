provider "aws" {
  alias  = "west2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "east1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "east2"
  region = "us-east-2"
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config {
    bucket = "gatewaychurch-static-terraform-state"
    key    = "global"
    region = "us-west-2"
  }
}

data "aws_route53_zone" "domain" {
  name = "${var.zone}"
}
