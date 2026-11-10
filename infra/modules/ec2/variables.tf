variable "ami_id" {
  description = "AMI ID for the EC2 instance (optional, defaults to latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to assign to the instance"
  type        = list(string)
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to execute on launch"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

