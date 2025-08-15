module "my-bucket" {
  source      = "..//terragrunt-modules//S3"
  environment = var.environment
  account_id  = var.account_id
  name        = "bucket-1"
  owner       = var.owner
}

module "my-bucket-2" {
  source      = "..//terragrunt-modules//S3"
  environment = var.environment
  account_id  = var.account_id
  name        = "bucket-2"
  owner       = var.owner
}

module "my-bucket-3" {
  source      = "..//terragrunt-modules//S3"
  environment = var.environment
  account_id  = var.account_id
  name        = "bucket-3"
  owner       = var.owner
}