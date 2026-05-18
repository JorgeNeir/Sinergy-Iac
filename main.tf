# ============================================
# AWS Provider Configuration
# ============================================
provider "aws" {
  region = var.aws_region
}

# ============================================
# Módulo ECR - Repositorio de Docker
# ============================================
module "ecr" {
  source = "./modules/ecr"

  app_name    = var.app_name
  environment = var.environment
}

# ============================================
# Módulo IAM - Roles y Políticas
# ============================================
module "iam" {
  source = "./modules/iam"

  app_name           = var.app_name
  ecr_repository_arn = module.ecr.repository_arn
}

# ============================================
# Módulo App Runner - Servicio
# ============================================
module "apprunner" {
  source = "./modules/apprunner"

  app_name           = var.app_name
  environment        = var.environment
  ecr_repository_url = module.ecr.repository_url
  apprunner_role_arn = module.iam.apprunner_role_arn

  database_url       = var.database_url
  nextauth_url       = var.nextauth_url
  nextauth_secret    = var.nextauth_secret
  superuser_email    = var.superuser_email
  superuser_password = var.superuser_password
}