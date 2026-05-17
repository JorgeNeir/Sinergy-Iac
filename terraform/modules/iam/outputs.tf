output "apprunner_role_arn" {
  description = "App Runner IAM Role ARN"
  value       = aws_iam_role.apprunner_role.arn
}

output "operations_role_arn" {
  description = "Operations IAM Role ARN"
  value       = aws_iam_role.operations_role.arn
}