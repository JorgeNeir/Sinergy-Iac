# ============================================
# Variables para Producción
# ============================================

aws_region  = "us-east-1"
environment = "prod"
app_name    = "sinergy-inventario"

# RDS PostgreSQL
rds_instance_class = "db.t3.micro"

# App Runner - Imagen desde ECR
use_public_image = false

# NextAuth - URL se actualiza tras el primer deploy exitoso (ver output app_runner_service_url)
nextauth_url    = "https://2vhdmgm2tn.us-east-1.awsapprunner.com"
nextauth_secret = "CHANGE_TO_A_GENERATED_SECRET_KEY"

# Superusuario local - COMPLETAR
superuser_email    = "admin@sinergy.com"
superuser_password = "CHANGE_TO_A_SECURE_PASSWORD"