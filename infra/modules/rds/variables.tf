variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "engine" {
  description = "The database engine (postgres or mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "Database instance type"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "dbadmin"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID allowing access to the database"
  type        = string
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ (false for dev)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (true for dev/practice)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

