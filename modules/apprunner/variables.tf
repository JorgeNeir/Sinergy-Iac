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
  default     = ""
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

variable "staff_password" {
  description = "Default staff user password"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID for App Runner VPC connector"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for App Runner VPC connector"
  type        = list(string)
}