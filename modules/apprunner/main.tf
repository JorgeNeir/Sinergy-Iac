resource "aws_apprunner_service" "app_service" {
  service_name = var.app_name

  dynamic "source_configuration" {
    for_each = var.use_public_image ? [1] : []
    content {
      image_repository {
        image_identifier      = var.public_image
        image_repository_type = "ECR_PUBLIC"

        image_configuration {
          port = "3000"
          runtime_environment_variables = {
            DATABASE_URL       = var.database_url
            NEXTAUTH_URL       = var.nextauth_url
            NEXTAUTH_SECRET    = var.nextauth_secret
            SUPERUSER_EMAIL    = var.superuser_email
            SUPERUSER_PASSWORD = var.superuser_password
          }
        }
      }

      auto_deployments_enabled = false
    }
  }

  dynamic "source_configuration" {
    for_each = var.use_public_image ? [] : [1]
    content {
      authentication_configuration {
        access_role_arn = var.apprunner_role_arn
      }

      image_repository {
        image_identifier      = "${var.ecr_repository_url}:latest"
        image_repository_type = "ECR"

        image_configuration {
          port = "3000"
          runtime_environment_variables = {
            DATABASE_URL       = var.database_url
            NEXTAUTH_URL       = var.nextauth_url
            NEXTAUTH_SECRET    = var.nextauth_secret
            SUPERUSER_EMAIL    = var.superuser_email
            SUPERUSER_PASSWORD = var.superuser_password
          }
        }
      }

      auto_deployments_enabled = false
    }
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = var.use_public_image ? "" : var.apprunner_role_arn
  }

  health_check_configuration {
    protocol          = "HTTP"
    path              = "/"
    interval          = 10
    timeout           = 5
    healthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Name        = var.app_name
  }
}