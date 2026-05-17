resource "aws_apprunner_service" "app_service" {
  service_name = var.app_name

  source_configuration {
    image_repository {
      image_identifier      = "${var.ecr_repository_url}:latest"
      image_repository_type = "ECR"

      auto_deployment_configuration {
        enabled = true
      }
    }

    instance_configuration {
      cpu    = "1024"  # 1 vCPU
      memory = "2048"  # 2 GB

      environment_secrets = [
        {
          name  = "DATABASE_URL"
          value = var.database_url
        },
        {
          name  = "NEXTAUTH_URL"
          value = var.nextauth_url
        },
        {
          name  = "NEXTAUTH_SECRET"
          value = var.nextauth_secret
        },
        {
          name  = "SUPERUSER_EMAIL"
          value = var.superuser_email
        },
        {
          name  = "SUPERUSER_PASSWORD"
          value = var.superuser_password
        }
      ]

      health_check_configuration {
        protocol          = "HTTP"
        path              = "/"
        interval          = 30
        timeout           = 5
        healthy_threshold = 3
      }
    }
  }

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}