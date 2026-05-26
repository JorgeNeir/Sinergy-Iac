# Escenarios: Infraestructura AWS
> BDD — Behavior-Driven Development  
> Escenarios de comportamiento esperado de la infraestructura.  
> "El usuario" aquí es el desarrollador que opera el workflow.

---

## Feature: Deploy de infraestructura (deploy.yml)

### Escenario 1: Primer deploy desde cero
```
Given  no existe ningún recurso de Sinergy en AWS
And    los secretos están configurados en GitHub
When   el desarrollador ejecuta "🚀 AWS Infrastructure Deployment"
Then   después de ~15-20 minutos:
         App Runner está en estado RUNNING
         RDS está en estado available
         VPC, subnets, NAT Gateway existen
         ECR repository existe
And    el workflow imprime la URL pública del App Runner
And    la app responde 200 en GET /api/health
```

### Escenario 2: Re-deploy sin cambios de infraestructura
```
Given  la infraestructura ya existe y App Runner está RUNNING
When   el desarrollador ejecuta el workflow de deploy
Then   terraform plan muestra "No changes"
And    el workflow termina exitosamente en < 3 minutos
And    App Runner sigue en estado RUNNING sin interrupción
```

### Escenario 3: Deploy con nueva variable de entorno
```
Given  la infraestructura existe
And    se agrega una nueva variable al módulo apprunner (ej: NEW_FEATURE_FLAG)
And    el secreto correspondiente existe en GitHub
When   el desarrollador ejecuta el workflow de deploy
Then   terraform plan muestra un cambio en el recurso App Runner
And    App Runner hace rolling restart con la nueva variable
And    la app sigue respondiendo durante el restart
```

### Escenario 4: Deploy falla por imagen de ECR no encontrada
```
Given  ECR no tiene imagen con tag "latest"
When   el workflow de deploy intenta crear el App Runner
Then   App Runner entra en estado CREATE_FAILED
And    el workflow falla con error descriptivo
And    RDS y VPC quedan creados (no se hace rollback parcial)
```

---

## Feature: Pausa de infraestructura (pause.yml)

### Escenario 5: Pause exitoso
```
Given  App Runner está en estado RUNNING
And    RDS está en estado available
When   el desarrollador ejecuta "⏸️ Pause Infrastructure"
Then   App Runner es eliminado
And    RDS es eliminado
And    ECR, S3 (estado Terraform) y VPC permanecen
And    el workflow termina exitosamente
```

### Escenario 6: Pause cuando App Runner está en OPERATION_IN_PROGRESS
```
Given  App Runner está en estado OPERATION_IN_PROGRESS (ej: haciendo deploy)
When   el desarrollador ejecuta el workflow de pause
Then   el workflow espera hasta que App Runner salga de OPERATION_IN_PROGRESS
And    una vez en estado estable, procede con terraform destroy
And    no falla por InvalidStateException
```

### Escenario 7: Re-deploy después de pause
```
Given  la infraestructura fue pausada (App Runner y RDS eliminados)
And    ECR tiene la imagen latest
When   el desarrollador ejecuta el workflow de deploy
Then   App Runner y RDS se recrean
And    la app funciona como antes del pause
And    los datos en RDS están vacíos (RDS fue destruido)
```

---

## Feature: Seguridad de la infraestructura

### Escenario 8: RDS no es accesible desde internet
```
Given  RDS está en estado available
When   se intenta conectar a RDS desde una IP pública externa
       (ej: nc -zv <rds-endpoint> 5432)
Then   la conexión es rechazada / timeout
And    solo App Runner (vía VPC connector) puede conectarse
```

### Escenario 9: Secretos no aparecen en logs
```
Given  el workflow de deploy está corriendo
When   se revisan los logs de GitHub Actions
Then   ningún valor de variable sensible (passwords, secrets) aparece en texto plano
And    los valores aparecen como "***" en los logs
```

### Escenario 10: Imagen ECR no accesible públicamente
```
Given  ECR repository existe con imagen latest
When   se intenta hacer docker pull desde fuera de AWS sin credenciales
Then   el pull falla con error de autenticación
```

---

## Feature: Observabilidad

### Escenario 11: Logs de App Runner disponibles
```
Given  App Runner está RUNNING y procesando requests
When   el desarrollador consulta CloudWatch Logs
       /aws/apprunner/sinergy-inventario/<id>/application
Then   ve los logs de stdout del contenedor Next.js
And    los logs incluyen errores de la app si los hay
```

### Escenario 12: Health check detecta app caída
```
Given  App Runner está configurado con health check en /api/health
When   la app dentro del contenedor falla (crash, OOM, etc.)
Then   App Runner detecta el fallo vía health check
And    intenta restart automático del contenedor
And    si no se recupera en N intentos, el servicio queda en estado degradado
```

---

## Criterios de aceptación globales de la IaC

- [ ] `terraform validate` pasa sin errores en todos los módulos
- [ ] `terraform fmt -check` pasa (código formateado)
- [ ] Ninguna variable sensible tiene `default` con valor real en el código
- [ ] El state de Terraform está en S3, no localmente
- [ ] Todos los recursos tienen el tag `app_name` para identificación y costos
- [ ] ECR sobrevive al `pause.yml` (no se destruye con la infra)
- [ ] El destroy.yml requiere confirmación explícita antes de ejecutar
