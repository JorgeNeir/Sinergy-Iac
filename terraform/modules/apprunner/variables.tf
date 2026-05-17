variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR Repository URL"
  type        = string
}

variable "apprunner_role_arn" {
  description = "App Runner IAM Role ARN"
  type        = string
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