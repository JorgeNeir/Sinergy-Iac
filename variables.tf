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