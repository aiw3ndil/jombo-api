# Quick Start Guide - Coolify Deployment

## 🚀 Deploy en 5 Minutos

### 1. Pre-requisitos
- Cuenta en Coolify
- Repositorio Git del proyecto
- Dominio (opcional)

### 2. Crear App en Coolify

1. **New Resource** → **Application** (NO Docker Compose)
2. **Repository**: Pega la URL de tu repo Git
3. **Branch**: `main`
4. **Build Pack**: Dockerfile

### 3. Variables de Entorno Mínimas

```env
SECRET_KEY_BASE=<ejecuta: rails secret>
RAILS_MASTER_KEY=<copia de config/master.key>
POSTGRES_USER=jombo
POSTGRES_PASSWORD=<genera_password_segura>
POSTGRES_DB=jombo_production
RAILS_ENV=production
PORT=3000
DATABASE_URL=postgresql://jombo:<password>@<db_host>:5432/jombo_production
```

### 4. Configurar Base de Datos

1. En Coolify → **Add Database** → PostgreSQL
2. Conecta la DB a tu aplicación
3. Coolify generará automáticamente `DATABASE_URL`

### 4. Deploy

Click en **"Deploy"** y espera ~5 minutos.

**⚠️ Si ves error "exporting to image":**
1. Ver [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Verificar que tienes >2GB RAM y >10GB disco
3. Intentar: Settings → Build Pack → Nixpacks

### 5. Verificar

```bash
curl https://tu-dominio.com/health
```

Deberías ver:
```json
{
  "status": "ok",
  "timestamp": "2025-12-02T19:30:00Z",
  "environment": "production",
  "version": "1.0.0"
}
```

---

## 📋 Checklist Post-Deployment

- [ ] Health check responde OK: `/health`
- [ ] Database conectada: `/health/database`
- [ ] Puedes registrar usuario: `POST /api/v1/register`
- [ ] Puedes hacer login: `POST /api/v1/login`
- [ ] SSL/HTTPS funcionando

---

## 🔧 Comandos Útiles

### Ver Logs
En Coolify → Tu App → **Logs** → Seleccionar servicio

### Ejecutar Consola Rails
```bash
docker exec -it <container_id> rails console
```

### Ejecutar Migraciones
```bash
docker exec -it <container_id> rails db:migrate
```

### Resetear Base de Datos (⚠️ CUIDADO)
```bash
docker exec -it <container_id> rails db:reset
```

---

## 🆘 Troubleshooting Rápido

### Error: "SECRET_KEY_BASE missing"
→ Genera uno nuevo: `rails secret` y añádelo a variables de entorno

### Error: "Database connection failed"
→ Verifica que PostgreSQL esté corriendo:
```bash
docker ps | grep postgres
```

### Error: "RAILS_MASTER_KEY invalid"
→ Copia el correcto desde `config/master.key`

### App no responde
→ Revisa logs en Coolify
→ Verifica que el puerto 3000 esté expuesto

---

## 📚 Documentación Completa

Ver [DEPLOYMENT.md](./DEPLOYMENT.md) para guía completa.

---

## 🔐 Seguridad

✅ Siempre usa:
- Passwords fuertes (>20 caracteres)
- HTTPS (Coolify lo configura automáticamente)
- Variables de entorno (nunca hardcodear)

❌ Nunca commitees:
- `config/master.key`
- `.env` con datos reales
- Passwords en el código

---

## 📊 Recursos Recomendados

**Mínimo (desarrollo/testing):**
- 2 CPU cores
- 2 GB RAM
- 20 GB storage

**Recomendado (producción):**
- 4 CPU cores
- 4 GB RAM
- 40 GB storage

**Escalado (alto tráfico):**
- 8+ CPU cores
- 8+ GB RAM
- 100+ GB storage

---

## 🌐 Endpoints Principales

- `GET /health` - Health check
- `GET /health/database` - Database health
- `POST /api/v1/register` - Registro
- `POST /api/v1/login` - Login
- `GET /api/v1/trips` - Listar viajes
- `POST /api/v1/trips` - Crear viaje
- `POST /api/v1/bookings` - Crear reserva

Ver [README.md](./README.md) para documentación completa de la API.

---

## 💡 Tips

1. **Backups automáticos**: Configura en Coolify Pro
2. **Monitoreo**: Usa health checks para alertas
3. **Logs**: Mantén por al menos 7 días
4. **Updates**: Deploy nuevos cambios con un click
5. **Staging**: Crea un environment de staging primero

---

## 🎯 Próximos Pasos

1. ✅ Deploy básico funcionando
2. Configure dominio personalizado
3. Configure emails (Enkimail)
4. Configure backups automáticos
5. Configure monitoreo/alertas
6. Configure staging environment

---

## 📞 Soporte

- Coolify Docs: https://coolify.io/docs
- Rails Guides: https://guides.rubyonrails.org
- Issues: Abre un issue en el repo
