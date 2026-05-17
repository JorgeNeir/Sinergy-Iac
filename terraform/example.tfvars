# ============================================
# Ejemplo de archivo de variables
# Copia este archivo y renómbralo según el entorno
# cp example.tfvars dev.tfvars
# ============================================

aws_region    = "us-east-1"          # región de AWS
environment   = "dev"                 # dev, staging, prod
app_name       = "sinergy-inventario" # nombre de la app

# ============================================
# DATABASE - PostgreSQL (AWS RDS)
# ============================================
# Formato: postgresql://username:password@host:port/database
database_url = "postgresql://postgres:password@your-rds-endpoint.rds.amazonaws.com:5432/sinergy_inventory"

# ============================================
# NEXTAUTH
# ============================================
nextauth_url    = "https://your-app-url.apprunner.aws.com"
nextauth_secret = "generate-a-secure-random-string-here"

# ============================================
# SUPERUSER LOCAL (Break-Glass)
# ============================================
superuser_email    = "admin@sinergy.com"
superuser_password = "change-this-password"