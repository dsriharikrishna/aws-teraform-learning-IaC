variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE" # Set to IMMUTABLE in strict prod environments
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Number of images to retain before lifecycle policy expires old ones"
  type        = number
  default     = 10
}

variable "environment" {
  description = "Deployment environment (dev, stg, prod)"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

