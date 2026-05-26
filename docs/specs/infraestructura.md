# Spec: Infraestructura AWS — Sinergy Inventario
> SDD — Spec-Driven Development  
> Este archivo define el contrato de la infraestructura.  
> Claude debe leerlo antes de modificar cualquier `.tf` o workflow.

---

## 1. Visión general

Sinergy Inventario corre en AWS con la siguiente arquitectura:

```
Internet
    │
    ▼
App Runner (contenedor Next.js)
    │  VPC Connector
    ▼
RDS PostgreSQL (subred privada)
    │  NAT Gateway
    ▼
Internet (para pulls de ECR y llamadas externas)
```

**Stack:**
- **App Runner** — servidor web, escala a cero automáticamente
- **RDS PostgreSQL t3.micro** — base de datos en subred privada
- **ECR** — registro Docker privado
- **VPC + NAT Gateway** — red privada para RDS
- **IAM** — roles mínimos necesarios para App Runner → ECR

---

## 2. Módulos y responsabilidades

| Módulo | Directorio | Responsabilidad |
|--------|-----------|-----------------|
| `network` | `modules/network/` | VPC, subnets públicas/privadas, NAT Gateway, Internet Gateway |
| `ecr` | `modules/ecr/` | Repositorio Docker privado, lifecycle policy |
| `iam` | `modules/iam/` | Role de App Runner para pull de ECR |
| `rds` | `modules/rds/` | Instancia PostgreSQL, security group, subnet group |
| `apprunner` | `modules/apprunner/` | Servicio App Runner, VPC connector, variables de entorno |

**Regla:** Cada módulo es independiente. El root `main.tf` ensambla los outputs de un módulo como inputs del siguiente.

---

## 3. Variables requeridas vs opcionales

### Requeridas (sin valor por defecto — deben estar en GitHub Secrets)
| Variable | Descripción | Secreto GitHub |
|----------|-------------|----------------|
| `rds_master_password` | Password de PostgreSQL | `DB_PASSWORD` |
| `nextauth_url` | URL pública del App Runner | `NEXTAUTH_URL` |
| `nextauth_secret` | Clave para firmar JWT | `NEXTAUTH_SECRET` |
| `superuser_email` | Email del admin inicial | `SUPERUSER_EMAIL` |
| `superuser_password` | Password del admin inicial | `SUPERUSER_PASSWORD` |
| `staff_password` | Password del usuario staff inicial | `STAFF_PASSWORD` |

### Opcionales (con default)
| Variable | Default | Cuándo cambiar |
|----------|---------|----------------|
| `aws_region` | `us-east-1` | Si se cambia región |
| `environment` | `dev` | Cuando haya staging/prod |
| `app_name` | `sinergy-inventario` | Nunca (es el identificador único) |
| `rds_instance_class` | `db.t3.micro` | Si se necesita más capacidad |

---

## 4. Reglas de seguridad invariantes

1. **RDS nunca es publicly_accessible** — Solo accesible vía VPC connector desde App Runner
2. **Passwords nunca en código** — Solo en GitHub Secrets, pasados como `-var` en el workflow
3. **ECR es privado** — App Runner accede vía IAM role, no credenciales explícitas
4. **State en S3** — `backend.tf` usa bucket S3 + DynamoDB locking. Nunca usar state local en prod
5. **Un solo ambiente activo** — No existe staging/prod aún. Toda la infra vive en `us-east-1`

---

## 5. Contratos de los workflows de GitHub Actions

### `deploy.yml` — Aplicar infraestructura
- **Trigger:** manual (`workflow_dispatch`)
- **Pasos:**
  1. `terraform init` con backend S3
  2. `terraform plan` — muestra cambios
  3. `terraform apply -auto-approve` — aplica
  4. Imprime la URL del App Runner como output
- **Post-condición:** App Runner en estado `RUNNING`, RDS en estado `available`
- **Tiempo esperado:** 5-8 minutos (si no hay cambios de red) / 15-20 min (primer deploy)

### `pause.yml` — Destruir infraestructura (ahorro de costos)
- **Trigger:** manual (`workflow_dispatch`)
- **Pasos:**
  1. Espera que App Runner no esté en `OPERATION_IN_PROGRESS`
  2. `terraform destroy -auto-approve`
- **Excepción:** ECR **no** se destruye — preserva la imagen Docker
- **Post-condición:** App Runner y RDS eliminados. S3 y ECR intactos
- **Cuándo usarlo:** Cuando no se va a usar la app por >8 horas

### `destroy.yml` — Destrucción total
- **Trigger:** manual (requiere confirmación explícita en el workflow)
- **Destruye:** todo, incluyendo ECR e imágenes Docker
- **Advertencia:** Irreversible. Usar solo para eliminar el proyecto completo

---

## 6. Decisiones de diseño registradas

| Decisión | Razón |
|----------|-------|
| App Runner sobre ECS/EC2 | Cero configuración de clusters, escala a cero, más barato en bajo tráfico |
| RDS sobre Aurora Serverless | Aurora mínimo ~$50/mes, RDS t3.micro ~$14/mes para este volumen |
| NAT Gateway sobre acceso público a RDS | Seguridad: la DB nunca expone puerto 5432 a internet |
| Un solo ambiente (no dev/staging/prod) | MVP — la complejidad multi-ambiente se agrega cuando haya equipo |
| `nextauth_url` como variable (no hardcoded) | App Runner cambia URL cada deploy si se destruye el servicio |

---

## 7. Costo proyectado (infra siempre activa)

| Componente | $/mes |
|------------|-------|
| NAT Gateway (744 hrs × $0.045) | ~$33 |
| RDS t3.micro (744 hrs) | ~$14 |
| App Runner (1 vCPU / 2GB) | ~$5–15 |
| VPC / Elastic IP | ~$4 |
| ECR + S3 + DynamoDB | ~$0.50 |
| **Total** | **~$57–70** |

Créditos AWS actuales: $120 (vencen Jun 2027). Estrategia: usar `pause.yml` cuando no se trabaje activamente.
