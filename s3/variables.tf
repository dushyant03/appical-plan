# Global Variables
variable "account_id" {
  type        = number
  description = "Resource Accoun ID"
}
variable "region" {
  type        = string
  description = "AWS Deployment Region"
  default     = "eu-west-1"
}
variable "availability_zone" {
  type        = list(string)
  description = "type of availability_zone possible values: eu-west-1a eu-west-1b eu-west-1c"
  default     = ["eu-west-1a", "eu-west-1b"]
}
variable "environment" {
  type        = string
  description = "type of environment possible values: develop, release, production"
  validation {
    condition     = contains(["develop", "infrastructure", "production"], var.environment)
    error_message = "Valid values for var: test_variable are (develop, infrastructure, production)."
  }
}
variable "owner" {
  type        = string
  description = "Resource owner"
}

# Local variables
variable "cors_rules" {
  description = "List of CORS rules for the S3 bucket."
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = null
}

variable "bucket_policy" {
  description = "JSON-encoded bucket policy."
  type        = string
  default     = null
}