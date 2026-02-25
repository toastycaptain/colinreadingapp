variable "bucket_name" {
  description = "Name for the S3 bucket."
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable bucket versioning."
  type        = bool
  default     = true
}

variable "transition_to_glacier_days" {
  description = "Move objects to Glacier after N days. Null disables lifecycle transition."
  type        = number
  default     = null
}

variable "cors_rules" {
  description = "Optional CORS rules for the bucket."
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
