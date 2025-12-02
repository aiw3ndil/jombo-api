# Deployment Guide - Jombo API

## Deployment con Coolify

Coolify es una plataforma de deployment self-hosted que facilita el despliegue de aplicaciones usando Docker.

### Requisitos Previos

1. Servidor con Coolify instalado
2. Acceso al repositorio Git del proyecto
3. Dominio o subdominio configurado (opcional)

### Paso 1: Crear Nuevo Proyecto en Coolify

1. Accede a tu panel de Coolify
2. Crea un nuevo proyecto: **"Jombo API"**
3. Selecciona **"New Resource"** → **"Docker Compose"**

### Paso 2: Configurar el Repositorio

1. **Repository URL**: URL de tu repositorio Git
2. **Branch**: `main` (o la rama que uses)
3. **Build Pack**: Docker Compose

### Paso 3: Variables de Entorno

Configura las siguientes variables de entorno en Coolify:

#### Obligatorias

```bash
# Database
POSTGRES_USER=jombo_api
POSTGRES_PASSWORD=<genera_password_segura>
POSTGRES_DB=jombo_api_production

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=<genera_con_rails_secret>
RAILS_MASTER_KEY=<tu_master_key>

# Server
PORT=3000
```

#### Generar SECRET_KEY_BASE

En tu máquina local:
```bash
rails secret
```

#### RAILS_MASTER_KEY

Obtén el master key de tu proyecto:
```bash
cat config/master.key
```

**⚠️ IMPORTANTE**: Nunca commitees el `master.key` al repositorio.

#### Opcionales (Email)

```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=tu_email@gmail.com
SMTP_PASSWORD=tu_app_password
SMTP_DOMAIN=gmail.com
```

### Paso 4: Configurar el Dominio

1. En Coolify, ve a **"Domains"**
2. Añade tu dominio: `api.tudominio.com`
3. Coolify generará automáticamente certificados SSL con Let's Encrypt

### Paso 5: Desplegar

1. Click en **"Deploy"**
2. Coolify ejecutará:
   - Build de la imagen Docker
   - Creación de la base de datos PostgreSQL
   - Ejecución de migraciones (`rails db:prepare`)
   - Inicio del servidor Rails

### Paso 6: Verificar el Deployment

Accede a tu API:
```bash
curl https://api.tudominio.com/api/v1/health
```

O visita: `https://api.tudominio.com`

---

## Estructura del Deployment

### Servicios

1. **PostgreSQL**: Base de datos (puerto 5432)
2. **Rails App**: API server (puerto 3000)

### Volúmenes Persistentes

- `postgres_data`: Datos de PostgreSQL
- `storage_data`: Archivos subidos (Active Storage)

### Health Checks

- PostgreSQL: Verifica conexión cada 10 segundos
- Rails: Coolify monitorea automáticamente el puerto 3000

---

## Comandos Útiles en Coolify

### Ver Logs

1. En Coolify, ve a tu aplicación
2. Click en **"Logs"**
3. Selecciona el servicio (`app` o `db`)

### Ejecutar Comandos en el Contenedor

En el servidor donde está Coolify:

```bash
# Acceder al contenedor
docker exec -it <container_id> bash

# Ejecutar consola Rails
docker exec -it <container_id> rails console

# Ejecutar migraciones
docker exec -it <container_id> rails db:migrate

# Ver estado de la base de datos
docker exec -it <container_id> rails db:migrate:status
```

### Reiniciar la Aplicación

En Coolify:
1. Click en **"Restart"**
2. O usa el botón **"Redeploy"** para un despliegue completo

---

## Configuración de Base de Datos

La aplicación usa `DATABASE_URL` para conectarse a PostgreSQL:

```
postgresql://usuario:password@db:5432/database_name
```

Coolify configura esto automáticamente usando las variables de entorno.

---

## Backups

### Backup Manual de PostgreSQL

```bash
# En el servidor
docker exec <postgres_container> pg_dump -U jombo_api jombo_api_production > backup.sql
```

### Restaurar Backup

```bash
docker exec -i <postgres_container> psql -U jombo_api jombo_api_production < backup.sql
```

### Configurar Backups Automáticos

Coolify Pro incluye backups automáticos. Alternativamente, configura un cron job:

```bash
0 2 * * * docker exec <postgres_container> pg_dump -U jombo_api jombo_api_production > /backups/jombo_$(date +\%Y\%m\%d).sql
```

---

## Actualizar la Aplicación

1. Push cambios a tu repositorio Git
2. En Coolify, click **"Redeploy"**
3. Coolify:
   - Pull del código nuevo
   - Rebuild de la imagen
   - Ejecuta `rails db:prepare` (migraciones)
   - Reinicia el servidor

---

## Troubleshooting

### La aplicación no inicia

**Revisa logs:**
```bash
docker logs <container_id>
```

**Causas comunes:**
- `SECRET_KEY_BASE` no configurado
- Error en migraciones de base de datos
- `RAILS_MASTER_KEY` incorrecto

### Error de conexión a base de datos

**Verifica:**
1. PostgreSQL está corriendo
2. Credenciales correctas en variables de entorno
3. Health check de PostgreSQL está passing

```bash
docker exec <postgres_container> pg_isready -U jombo_api
```

### Migraciones pendientes

```bash
docker exec <container_id> rails db:migrate:status
docker exec <container_id> rails db:migrate
```

### Problemas con Active Storage (uploads)

**Verifica volumen:**
```bash
docker volume ls | grep storage
docker volume inspect <volume_name>
```

---

## Monitoreo

### Métricas Disponibles en Coolify

- CPU usage
- Memory usage
- Network I/O
- Container status

### Logs Centralizados

Todos los logs están disponibles en Coolify dashboard en tiempo real.

### Health Endpoint

Crea un endpoint de health check:

```ruby
# config/routes.rb
get '/health', to: proc { [200, {}, ['OK']] }
```

---

## Seguridad

### Variables Sensibles

✅ **Usa variables de entorno** para:
- Passwords de base de datos
- SECRET_KEY_BASE
- RAILS_MASTER_KEY
- Credenciales SMTP

❌ **Nunca commitees**:
- `config/master.key`
- `.env` files con datos reales
- Passwords en archivos de configuración

### SSL/TLS

Coolify configura automáticamente:
- Certificados SSL gratuitos (Let's Encrypt)
- Renovación automática
- Redirección HTTP → HTTPS

### Firewall

Coolify configura automáticamente:
- Solo puertos necesarios expuestos
- PostgreSQL no accesible desde internet
- Solo Rails app expuesta en puerto 3000

---

## Escalabilidad

### Aumentar Recursos

En Coolify, ajusta:
- CPU limits
- Memory limits
- Database connection pool

### Horizontal Scaling

Para múltiples instancias:
1. Usa load balancer de Coolify
2. Configura shared storage para Active Storage
3. Considera Redis para sessions/cache

---

## Costos Estimados

**Servidor Mínimo:**
- CPU: 2 cores
- RAM: 2 GB
- Storage: 20 GB
- ~$5-10/mes (DigitalOcean, Hetzner)

**Servidor Recomendado:**
- CPU: 4 cores
- RAM: 4 GB
- Storage: 40 GB
- ~$15-20/mes

---

## Support

Para problemas específicos:
1. Revisa logs en Coolify
2. Consulta documentación de Coolify: https://coolify.io/docs
3. Revisa este README y DEPLOYMENT.md

## Referencias

- [Coolify Documentation](https://coolify.io/docs)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deploying_rails_applications.html)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
