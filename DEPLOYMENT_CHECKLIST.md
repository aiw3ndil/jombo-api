# 📋 Deployment Checklist - Coolify

## Pre-Deployment

### 1. Código Listo
- [ ] `git status` limpio
- [ ] Todos los tests pasan
- [ ] `Dockerfile` tiene `libyaml-dev`
- [ ] `config/master.key` existe localmente (NO commitear)

### 2. Secrets Generados
```bash
# Generar SECRET_KEY_BASE
rails secret

# Verificar RAILS_MASTER_KEY
cat config/master.key
```

- [ ] SECRET_KEY_BASE generado
- [ ] RAILS_MASTER_KEY copiado

---

## Coolify Setup

### 1. Crear Aplicación

- [ ] New Resource → **Application** (NO Docker Compose)
- [ ] Repository conectado
- [ ] Branch: `main`
- [ ] Build Pack: **Dockerfile**

### 2. Crear Database

- [ ] New Resource → **PostgreSQL**
- [ ] Nombre: `jombo-db`
- [ ] Conectar a aplicación
- [ ] Verificar que `DATABASE_URL` se genera automáticamente

### 3. Variables de Entorno

En Application → Environment Variables:

```env
SECRET_KEY_BASE=<pegar_aqui>
RAILS_MASTER_KEY=<pegar_aqui>
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
```

- [ ] SECRET_KEY_BASE configurado
- [ ] RAILS_MASTER_KEY configurado
- [ ] RAILS_ENV=production
- [ ] RAILS_LOG_TO_STDOUT=true
- [ ] RAILS_SERVE_STATIC_FILES=true
- [ ] DATABASE_URL existe (auto-generado)

### 4. Configuración de Red

- [ ] Puerto: 3000 (default)
- [ ] Dominio configurado (opcional)
- [ ] SSL automático activado (Coolify lo hace)

---

## Deployment

### 1. Primera Deploy

- [ ] Click "Deploy"
- [ ] Esperar ~5 minutos
- [ ] Ver logs en tiempo real

### 2. Verificar Build

Logs esperados:
```
✓ Installing dependencies...
✓ bundle install succeeded
✓ Copying application code...
✓ Creating user rails...
✓ Build complete
```

### 3. Verificar Deploy

Logs esperados:
```
✓ Starting container...
✓ Running migrations (db:prepare)...
✓ Starting Rails server...
✓ Listening on 0.0.0.0:3000
```

---

## Post-Deployment

### 1. Health Checks

```bash
# Verificar salud general
curl https://tu-dominio.com/health
# Esperado: {"status":"ok","version":"1.0.0"}

# Verificar database
curl https://tu-dominio.com/health/database
# Esperado: {"status":"ok","database":"connected"}
```

- [ ] `/health` responde OK
- [ ] `/health/database` responde OK

### 2. API Endpoints

```bash
# Test registro
curl -X POST https://tu-dominio.com/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test User"
    }
  }'
```

- [ ] Registro funciona
- [ ] Login funciona
- [ ] Endpoints principales responden

### 3. Monitoreo

En Coolify Dashboard:

- [ ] CPU usage < 50%
- [ ] Memory usage < 80%
- [ ] No errores en logs
- [ ] Health checks passing

---

## Troubleshooting

### Build Falla

**Error: "yaml.h not found"**
- ✅ Ya corregido en Dockerfile
- Solución: `git pull` y redeploy

**Error: "exporting to image"**
- Ver QUICKFIX.md
- Cambiar a Build Pack: Nixpacks

### Deploy Falla

**Error: "DATABASE_URL not set"**
- Verificar database conectada
- Recrear conexión en Coolify

**Error: "SECRET_KEY_BASE missing"**
- Verificar variable de entorno
- Regenerar: `rails secret`

**Error: "RAILS_MASTER_KEY invalid"**
- Verificar copiaste el correcto
- Ubicación: `config/master.key`

### App No Responde

1. Ver logs: Coolify → Logs
2. Verificar container running: Coolify → Containers
3. Revisar health checks: Coolify → Health
4. SSH al servidor: Verificar recursos

```bash
# En el servidor
docker ps  # Ver containers
docker logs <container_id>  # Ver logs
free -h  # Ver memoria
df -h  # Ver disco
```

---

## Rollback

Si algo sale mal:

1. Coolify → Deployments → Previous
2. Click "Redeploy" en deploy anterior
3. Verificar que funciona

---

## Updates

Para deployar cambios:

1. Hacer cambios localmente
2. Commit y push
   ```bash
   git add .
   git commit -m "Description"
   git push
   ```
3. Coolify detecta cambios automáticamente
4. O click manual en "Redeploy"

---

## Backups

### Database

En Coolify:
- Configurar backups automáticos
- Frecuencia: Diaria
- Retención: 7 días

Manual:
```bash
# Backup
docker exec <postgres_container> pg_dump -U jombo jombo_production > backup.sql

# Restore
docker exec -i <postgres_container> psql -U jombo jombo_production < backup.sql
```

### Code

- Mantener código en Git
- Tag releases importantes
- Usar branches para features

---

## Monitoring

### Métricas a Observar

- Response times
- Error rates
- CPU/Memory usage
- Database connections
- Disk space

### Logs

```bash
# Ver logs en vivo
Coolify → Logs → Follow

# Buscar errores
Grep "ERROR" en logs
```

### Alertas

Configurar en Coolify:
- CPU > 80%
- Memory > 90%
- Disk > 85%
- Health checks failing

---

## Checklist Final

- [ ] Build exitoso
- [ ] Deploy exitoso
- [ ] Health checks OK
- [ ] API responde
- [ ] Database conectada
- [ ] SSL activo
- [ ] Dominio funciona
- [ ] Backups configurados
- [ ] Monitoreo activo
- [ ] Documentación actualizada

---

## Documentación

- QUICKFIX.md - Soluciones rápidas
- TROUBLESHOOTING.md - Guía completa
- COOLIFY.md - Guía de Coolify
- DEPLOYMENT.md - Referencia completa

---

## Soporte

- Coolify Docs: https://coolify.io/docs
- Rails Guides: https://guides.rubyonrails.org
- PostgreSQL Docs: https://www.postgresql.org/docs/

