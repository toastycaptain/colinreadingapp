variable "endpoint_url" {
  description = "Optional pre-discovered MediaConvert endpoint URL."
  type        = string
  default     = null
}

variable "job_template_name" {
  description = "Optional MediaConvert job template name used by Rails."
  type        = string
  default     = null
}
