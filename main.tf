# ============================================
# AWS Provider Configuration
# ============================================
provider "aws" {
  region = var.aws_region
}

# ============================================
# Módulo Network - VPC y Subnets
# ============================================
module "network" {
  source = "./modules/network"

  app_name    = var.app_name
  environment = var.environment
  aws_region  = var.aws_region
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
# Módulo RDS - Base de datos PostgreSQL
# ============================================
module "rds" {
  source = "./modules/rds"

  app_name        = var.app_name
  environment     = var.environment
  instance_class  = var.rds_instance_class
  master_password = var.rds_master_password
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.subnet_ids
}

# ============================================
# Módulo App Runner - Servicio
# ============================================
module "apprunner" {
  source = "./modules/apprunner"

  app_name            = var.app_name
  environment         = var.environment
  ecr_repository_url = module.ecr.repository_url
  apprunner_role_arn = module.iam.apprunner_role_arn
  use_public_image   = var.use_public_image
  public_image       = var.public_image

  database_url       = "postgresql://postgres:${var.rds_master_password}@${module.rds.endpoint}/sinergy_inventory"
  nextauth_url       = var.nextauth_url
  nextauth_secret    = var.nextauth_secret
  superuser_email    = var.superuser_email
  superuser_password = var.superuser_password
}