variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = "Managed by Terraform"
}

variable "secret_string" {
  description = "The secret payload string (typically JSON format)"
  type        = string
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "Number of days AWS waits before permanent deletion (0 for immediate deletion)"
  type        = number
  default     = 0 # 0 allows immediate cleanup during practice/destroy
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

