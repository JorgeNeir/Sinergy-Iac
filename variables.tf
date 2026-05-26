variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "sinergy-inventario-dev"
}

variable "database_url" {
  description = "PostgreSQL database connection URL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_master_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID for RDS"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
  default     = []
}

variable "use_public_image" {
  description = "Use public image instead of ECR"
  type        = bool
  default     = false
}

variable "public_image" {
  description = "Public Docker image (e.g., nginx:latest)"
  type        = string
  default     = ""
}

variable "nextauth_url" {
  description = "NextAuth URL for production"
  type        = string
}

variable "nextauth_secret" {
  description = "NextAuth secret for production"
  type        = string
  sensitive   = true
}

variable "superuser_email" {
  description = "Superuser email for emergency access"
  type        = string
}

variable "superuser_password" {
  description = "Superuser password for emergency access"
  type        = string
  sensitive   = true
}

variable "staff_password" {
  description = "Default staff user password"
  type        = string
  sensitive   = true
}