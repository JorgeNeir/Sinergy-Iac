resource "aws_db_instance" "postgres" {
  identifier     = var.app_name
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  port = 5432

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  vpc_security_group_ids = [aws_security_group.rds.id]

  db_subnet_group_name = aws_db_subnet_group.main.name

  skip_final_snapshot      = true
  delete_automated_backups = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name        = "${var.app_name}-rds-sg"
  }
}