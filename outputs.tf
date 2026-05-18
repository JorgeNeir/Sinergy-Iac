# Outputs de la infraestructura
output "app_runner_service_url" {
  description = "App Runner Service URL (Public)"
  value       = module.apprunner.service_url
}

output "app_runner_service_arn" {
  description = "App Runner Service ARN"
  value       = module.apprunner.service_arn
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = module.ecr.repository_arn
}