# ============================================
# Variables para Staging
# ============================================

aws_region  = "us-east-1"
environment = "staging"
app_name    = "sinergy-inventario-staging"

# Base de datos (RDS PostgreSQL)
database_url = "postgresql://postgres:StagingPassword123@staging-db.xxxx.us-east-1.rds.amazonaws.com:5432/sinergy_inventory"

# NextAuth
nextauth_url    = "https://sinergy-inventory-staging.xxxx.apprunner.aws.com"
nextauth_secret = "staging-secret-change-this"

# Superusuario local
superuser_email    = "admin@sinergy.com"
superuser_password = "staging-password"