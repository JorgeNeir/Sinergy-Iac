output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Private subnet IDs for RDS"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}