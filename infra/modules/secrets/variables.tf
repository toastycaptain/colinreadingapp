variable "secret_name" {
  description = "Secrets Manager secret name."
  type        = string
}

variable "description" {
  description = "Secret description."
  type        = string
  default     = "Managed by Terraform"
}

variable "kms_key_id" {
  description = "Optional KMS key ID/ARN for encrypting secret values."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before permanent deletion when secret is destroyed."
  type        = number
  default     = 7
}

variable "manage_secret_value" {
  description = "When true, Terraform manages a secret version value."
  type        = bool
  default     = false
}

variable "secret_string" {
  description = "Optional secret payload when Terraform manages secret value."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Tags for secret resources."
  type        = map(string)
  default     = {}
}
