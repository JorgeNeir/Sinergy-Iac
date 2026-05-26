#!/bin/bash
# ============================================================
# TDD — Tests de infraestructura: Sinergy IaC
#
# Equivalente a los tests unitarios pero para Terraform y AWS.
# Cada test verifica un escenario de docs/bdd/infraestructura.md
#
# Uso:
#   ./docs/tests/infraestructura.sh            # todos los tests
#   ./docs/tests/infraestructura.sh estaticos  # solo validaciones locales
#   ./docs/tests/infraestructura.sh vivos      # tests contra AWS real
#
# Requisitos:
#   - terraform instalado
#   - AWS CLI configurado con credenciales
#   - jq instalado
# ============================================================

set -e
REGION="us-east-1"
APP_NAME="sinergy-inventario"
PASS=0
FAIL=0

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo -e "${YELLOW}→${NC} $1"; }

# ============================================================
# GRUPO 1: Tests estáticos (no necesitan AWS activo)
# Corresponde a: Criterios de aceptación globales
# ============================================================
run_estaticos() {
  echo ""
  echo "══════════════════════════════════════"
  echo " Tests estáticos (sin AWS)"
  echo "══════════════════════════════════════"

  # Test E1: terraform fmt — código bien formateado
  info "Verificando formato Terraform..."
  if terraform fmt -check -recursive . > /dev/null 2>&1; then
    ok "terraform fmt: código formateado correctamente"
  else
    fail "terraform fmt: hay archivos sin formatear (corre: terraform fmt -recursive .)"
  fi

  # Test E2: terraform validate — sintaxis válida
  info "Validando sintaxis Terraform..."
  if terraform validate > /dev/null 2>&1; then
    ok "terraform validate: sintaxis válida"
  else
    fail "terraform validate: errores de sintaxis encontrados"
  fi

  # Test E3: No hay passwords hardcodeados en .tf files
  info "Buscando secretos hardcodeados..."
  HARDCODED=$(grep -r "password\s*=\s*\"[^\"]\+\"" --include="*.tf" . \
    --exclude-dir=".terraform" 2>/dev/null | grep -v "sensitive\|variable\|description" || true)
  if [ -z "$HARDCODED" ]; then
    ok "Seguridad: no hay passwords hardcodeados en .tf"
  else
    fail "Seguridad: passwords hardcodeados encontrados:"
    echo "$HARDCODED"
  fi

  # Test E4: Variables sensibles marcadas como sensitive = true
  info "Verificando variables sensibles..."
  SENSITIVE_VARS=("rds_master_password" "nextauth_secret" "superuser_password" "staff_password")
  for VAR in "${SENSITIVE_VARS[@]}"; do
    # Busca la variable y la siguiente línea donde debería estar sensitive
    if grep -A5 "variable \"$VAR\"" variables.tf 2>/dev/null | grep -q "sensitive.*true"; then
      ok "Variable $VAR tiene sensitive = true"
    else
      fail "Variable $VAR debería tener sensitive = true"
    fi
  done

  # Test E5: State backend configurado (no local)
  info "Verificando backend de state..."
  if grep -q "backend \"s3\"" backend.tf 2>/dev/null; then
    ok "State backend: S3 configurado"
  else
    fail "State backend: no se encontró configuración S3 en backend.tf"
  fi

  # Test E6: Todos los módulos requeridos existen
  info "Verificando módulos..."
  REQUIRED_MODULES=("network" "ecr" "iam" "rds" "apprunner")
  for MOD in "${REQUIRED_MODULES[@]}"; do
    if [ -d "modules/$MOD" ]; then
      ok "Módulo $MOD existe"
    else
      fail "Módulo $MOD no encontrado en modules/"
    fi
  done

  # Test E7: RDS nunca es publicly_accessible
  info "Verificando RDS no es público..."
  if grep -r "publicly_accessible" modules/rds/ 2>/dev/null | grep -q "false"; then
    ok "RDS: publicly_accessible = false"
  elif grep -r "publicly_accessible" modules/rds/ 2>/dev/null | grep -q "true"; then
    fail "RDS: publicly_accessible = true — RIESGO DE SEGURIDAD"
  else
    ok "RDS: publicly_accessible no definido (default false en AWS)"
  fi
}

# ============================================================
# GRUPO 2: Tests vivos (requieren infra activa en AWS)
# Corresponde a: Escenarios BDD 1, 5, 8, 9, 11
# ============================================================
run_vivos() {
  echo ""
  echo "══════════════════════════════════════"
  echo " Tests vivos (requieren AWS)"
  echo "══════════════════════════════════════"

  # Test V1 (BDD Escenario 1): App Runner está RUNNING
  info "Verificando estado de App Runner..."
  STATUS=$(aws apprunner list-services --region $REGION \
    --query "ServiceSummaryList[?contains(ServiceName,'$APP_NAME')].Status" \
    --output text 2>/dev/null || echo "NOT_FOUND")

  if [ "$STATUS" = "RUNNING" ]; then
    ok "App Runner: estado RUNNING"
  elif [ "$STATUS" = "NOT_FOUND" ] || [ -z "$STATUS" ]; then
    fail "App Runner: servicio no encontrado (¿infra pausada?)"
  else
    fail "App Runner: estado $STATUS (esperado: RUNNING)"
  fi

  # Test V2 (BDD Escenario 1): /api/health responde 200
  info "Verificando health check..."
  SERVICE_URL=$(aws apprunner list-services --region $REGION \
    --query "ServiceSummaryList[?contains(ServiceName,'$APP_NAME')].ServiceUrl" \
    --output text 2>/dev/null || echo "")

  if [ -n "$SERVICE_URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      "https://$SERVICE_URL/api/health" --max-time 10 || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      ok "Health check: GET /api/health → 200 OK"
    else
      fail "Health check: GET /api/health → $HTTP_CODE (esperado: 200)"
    fi
  else
    fail "Health check: no se puede obtener URL del servicio"
  fi

  # Test V3 (BDD Escenario 8): RDS no accesible desde internet
  info "Verificando que RDS no sea accesible públicamente..."
  RDS_ENDPOINT=$(aws rds describe-db-instances --region $REGION \
    --query "DBInstances[?contains(DBInstanceIdentifier,'$APP_NAME')].Endpoint.Address" \
    --output text 2>/dev/null || echo "")

  if [ -n "$RDS_ENDPOINT" ]; then
    # Intenta conectar — debería fallar (timeout)
    if nc -zw 3 "$RDS_ENDPOINT" 5432 2>/dev/null; then
      fail "Seguridad: RDS puerto 5432 accesible desde internet — RIESGO"
    else
      ok "Seguridad: RDS no accesible desde internet (correcto)"
    fi
  else
    info "RDS no encontrado — test de acceso omitido"
  fi

  # Test V4 (BDD Escenario 9): Logs de CloudWatch existen
  info "Verificando logs de App Runner en CloudWatch..."
  SERVICE_ID=$(aws apprunner list-services --region $REGION \
    --query "ServiceSummaryList[?contains(ServiceName,'$APP_NAME')].ServiceId" \
    --output text 2>/dev/null || echo "")

  if [ -n "$SERVICE_ID" ]; then
    LOG_GROUP="/aws/apprunner/$APP_NAME/$SERVICE_ID/application"
    if aws logs describe-log-groups --log-group-name "$LOG_GROUP" \
       --region $REGION --query "logGroups[0].logGroupName" \
       --output text 2>/dev/null | grep -q "$APP_NAME"; then
      ok "CloudWatch: log group de aplicación existe"
    else
      fail "CloudWatch: log group no encontrado — logs no configurados"
    fi
  fi

  # Test V5: ECR tiene imagen latest
  info "Verificando imagen en ECR..."
  IMAGE=$(aws ecr describe-images --repository-name $APP_NAME \
    --region $REGION \
    --query "imageDetails[?contains(imageTags,'latest')].imageTags" \
    --output text 2>/dev/null || echo "")

  if echo "$IMAGE" | grep -q "latest"; then
    ok "ECR: imagen con tag 'latest' existe"
  else
    fail "ECR: no hay imagen con tag 'latest'"
  fi
}

# ============================================================
# GRUPO 3: terraform plan (no aplica, solo planifica)
# ============================================================
run_plan() {
  echo ""
  echo "══════════════════════════════════════"
  echo " Terraform Plan (drift detection)"
  echo "══════════════════════════════════════"

  info "Ejecutando terraform plan..."
  PLAN_OUTPUT=$(terraform plan -no-color 2>&1 | tail -5)

  if echo "$PLAN_OUTPUT" | grep -q "No changes"; then
    ok "Terraform: infraestructura sincronizada con el código"
  elif echo "$PLAN_OUTPUT" | grep -q "to add\|to change\|to destroy"; then
    fail "Terraform: hay drift — el estado real difiere del código:"
    echo "$PLAN_OUTPUT"
  else
    fail "Terraform: plan falló con error"
    echo "$PLAN_OUTPUT"
  fi
}

# ============================================================
# Ejecutar según argumento
# ============================================================
MODO=${1:-"todos"}

case "$MODO" in
  "estaticos")
    run_estaticos
    ;;
  "vivos")
    run_vivos
    ;;
  "plan")
    run_plan
    ;;
  "todos"|*)
    run_estaticos
    run_vivos
    ;;
esac

# Resumen
echo ""
echo "══════════════════════════════════════"
echo -e " Resultado: ${GREEN}$PASS pasaron${NC} | ${RED}$FAIL fallaron${NC}"
echo "══════════════════════════════════════"

[ $FAIL -eq 0 ] && exit 0 || exit 1
