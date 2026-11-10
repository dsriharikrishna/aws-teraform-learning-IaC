variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags for the security groups"
  type        = map(string)
  default     = {}
}
