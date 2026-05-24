resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.app_name}-vpc-connector"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.apprunner_vpc.id]

  tags = {
    Environment = var.environment
    Name        = "${var.app_name}-vpc-connector"
  }
}

resource "aws_security_group" "apprunner_vpc" {
  name        = "${var.app_name}-apprunner-vpc-sg"
  description = "Security group for App Runner VPC connector"
  vpc_id      = var.vpc_id

  tags = {
    Environment = var.environment
    Name        = "${var.app_name}-apprunner-vpc-sg"
  }
}

resource "aws_apprunner_service" "app_service" {
  service_name = var.app_name

  source_configuration {
    image_repository {
      image_identifier      = var.use_public_image ? var.public_image : "${var.ecr_repository_url}:latest"
      image_repository_type = var.use_public_image ? "ECR_PUBLIC" : "ECR"

      image_configuration {
        port = var.use_public_image ? "80" : "3000"
        runtime_environment_variables = {
          HOSTNAME           = "0.0.0.0"
          DATABASE_URL       = var.database_url
          NEXTAUTH_URL       = var.nextauth_url
          NEXTAUTH_SECRET    = var.nextauth_secret
          SUPERUSER_EMAIL    = var.superuser_email
          SUPERUSER_PASSWORD = var.superuser_password
        }
      }
    }

    dynamic "authentication_configuration" {
      for_each = var.use_public_image ? [] : [1]
      content {
        access_role_arn = var.apprunner_role_arn
      }
    }

    auto_deployments_enabled = false
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  health_check_configuration {
    protocol          = "HTTP"
    path              = "/api/health"
    interval          = 10
    timeout           = 5
    healthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}