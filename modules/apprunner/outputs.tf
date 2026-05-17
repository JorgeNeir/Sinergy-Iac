output "service_url" {
  description = "App Runner Service URL (Public)"
  value       = aws_apprunner_service.app_service.service_url
}

output "service_arn" {
  description = "App Runner Service ARN"
  value       = aws_apprunner_service.app_service.arn
}