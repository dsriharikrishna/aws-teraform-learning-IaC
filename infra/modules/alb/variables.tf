variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and Target Group will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs across multiple AZs for the ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID attached to the ALB"
  type        = string
}

variable "target_port" {
  description = "Port the backend application listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

