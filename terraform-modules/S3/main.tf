module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket        = "myt-${var.name}-${var.environment}"
  attach_policy = var.bucket_policy != null ? true : false
  cors_rule     = var.cors_rules != [] ? var.cors_rules : []
  policy        = var.bucket_policy != null ? var.bucket_policy : null
  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}