# Skill: deploy-iac
> Skill personalizado para Claude — procedimiento de deploy de infraestructura.
> Invocar con: "Claude, sigue el skill deploy-iac"

---

## Cuándo usar este skill

Cuando el desarrollador pide: "despliega la infraestructura", "levanta el ambiente",
"corre el deploy de IaC", o después de un pause quiere volver a levantar todo.

---

## Procedimiento

### Paso 1: Verificar estado previo
```bash
# ¿Hay infra activa?
aws apprunner list-services --region us-east-1 \
  --query "ServiceSummaryList[?contains(ServiceName,'sinergy-inventario')]"

# ¿ECR tiene imagen?
aws ecr describe-images --repository-name sinergy-inventario \
  --region us-east-1 \
  --query "imageDetails[?contains(imageTags,'latest')]"
```

**Si App Runner ya está RUNNING:** preguntar al usuario si quiere forzar redeploy.  
**Si ECR no tiene imagen:** informar que hay que correr primero el CI de Sinergy-App.

### Paso 2: Indicar al usuario que corra el workflow
No ejecutar Terraform directamente — el deploy va vía GitHub Actions para tener:
- Registro de quién deployó y cuándo
- Logs en GitHub
- Secrets manejados por GitHub, no expuestos localmente

Indicar al usuario:
> "Ve a **Sinergy-Iac → Actions → 🚀 AWS Infrastructure Deployment → Run workflow**"

### Paso 3: Monitorear el resultado
```bash
# Esperar a que el servicio esté RUNNING (máx 20 min)
# Verificar cada 30 segundos
aws apprunner list-services --region us-east-1 \
  --query "ServiceSummaryList[?contains(ServiceName,'sinergy-inventario')].Status"
```

### Paso 4: Verificar con los tests
```bash
cd /ruta/a/Sinergy-Iac
bash docs/tests/infraestructura.sh vivos
```

### Paso 5: Reportar al usuario
- URL del servicio
- Estado de cada test
- Costo estimado del deploy (ver docs/specs/infraestructura.md §7)

---

## Si el deploy falla

1. Leer los logs de CloudWatch del App Runner:
   ```bash
   # Ver últimos eventos del servicio
   aws apprunner list-operations \
     --service-arn <arn> --region us-east-1
   ```
2. Si es `CREATE_FAILED`: ver logs de la instancia en CloudWatch
3. Consultar `docs/bdd/infraestructura.md` Escenario 4 para diagnóstico

---

## Restricciones de este skill

- **Nunca** correr `terraform apply` localmente — siempre vía GitHub Actions
- **Nunca** hacer `terraform destroy` sin confirmación explícita del usuario
- **Nunca** modificar variables en `prod.tfvars` sin revisar primero la spec
