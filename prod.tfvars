# ============================================
# Variables para Producción
# ============================================

aws_region  = "us-east-1"
environment = "prod"
app_name    = "sinergy-inventario"

# Base de datos (RDS PostgreSQL) - COMPLETAR
database_url = "postgresql://postgres:YOUR_PROD_PASSWORD@prod-db.xxxx.us-east-1.rds.amazonaws.com:5432/sinergy_inventory"

# NextAuth - COMPLETAR
nextauth_url    = "https://sinergy-inventory.xxxx.apprunner.aws.com"
nextauth_secret = "CHANGE_TO_A_GENERATED_SECRET_KEY"

# Superusuario local - COMPLETAR
superuser_email    = "admin@sinergy.com"
superuser_password = "CHANGE_TO_A_SECURE_PASSWORD"