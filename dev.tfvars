# ============================================
# Variables para Desarrollo
# ============================================

aws_region  = "us-east-1"
environment = "dev"
app_name    = "sinergy-inventario-dev"

# Base de datos (RDS PostgreSQL)
database_url = "postgresql://postgres:DevPassword123@dev-db.xxxx.us-east-1.rds.amazonaws.com:5432/sinergy_inventory"

# NextAuth
nextauth_url    = "https://sinergy-inventory-dev.xxxx.apprunner.aws.com"
nextauth_secret = "dev-secret-change-this-in-prod"

# Superusuario local
superuser_email    = "admin@sinergy.com"
superuser_password = "adminsinergy2024*"