output "endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.postgres.arn
}