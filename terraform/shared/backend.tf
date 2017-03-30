# 
# initialize with `$ terraform init -backend-config 'key=project/environment'`
# for the appropriate values of project and environment
# e.g.: terraform init -backend-config 'key=pinkimpact-static/stage'
terraform {
  backend "s3" {
    bucket     = "gatewaychurch-static-terraform-state-dev"
#    key        = 
    encrypt    = "1"
    acl        = "private"
    region     = "us-west-2"
    lock_table = "gatewaychurch-static-terraform-lock"
  }
}
