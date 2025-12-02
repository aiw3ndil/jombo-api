# Troubleshooting Guide - Docker Build Errors

## Error: "exporting to image" Failed

### Síntomas
```
#20 exporting to image
#20 exporting layers
Error type: RuntimeException
```

### Causas Comunes

1. **Falta de espacio en disco**
2. **Memoria insuficiente**
3. **Multi-stage build issues en Coolify**
4. **Permisos incorrectos**

### Soluciones

#### Opción 1: Usar Dockerfile Simplificado (Recomendado)

El Dockerfile ha sido optimizado para evitar problemas con multi-stage builds.

**Verificar que estás usando el Dockerfile correcto:**
```bash
# El Dockerfile debe tener una sola etapa, sin "FROM ... as base"
head -20 Dockerfile
```

#### Opción 2: Verificar Recursos del Servidor

```bash
# Verificar espacio en disco
df -h

# Verificar memoria
free -h

# Limpiar caché de Docker
docker system prune -a --volumes
```

**Requerimientos mínimos:**
- Espacio: 10 GB libres
- RAM: 2 GB disponibles
- CPU: 2 cores

#### Opción 3: Usar Docker Compose Simplificado

En Coolify, cambia la configuración:

1. En lugar de usar `docker-compose.yml`, usa `docker-compose.simple.yml`
2. O configura Coolify para usar solo el Dockerfile directamente

**Configuración en Coolify:**
```
Build Type: Dockerfile
Dockerfile Path: ./Dockerfile
```

#### Opción 4: Build Local y Push

Si persisten los problemas, haz el build localmente:

```bash
# Build local
docker build -t jombo-api:latest .

# Tag para tu registry
docker tag jombo-api:latest registry.example.com/jombo-api:latest

# Push al registry
docker push registry.example.com/jombo-api:latest

# En Coolify, usa la imagen directamente
```

### Variables de Entorno Necesarias

Asegúrate de tener configuradas en Coolify:

```env
# Base de datos
POSTGRES_USER=jombo
POSTGRES_PASSWORD=<tu_password>
POSTGRES_DB=jombo_production

# Rails
SECRET_KEY_BASE=<rails secret>
RAILS_MASTER_KEY=<master.key>
RAILS_ENV=production
```

### Verificar el Build Localmente

```bash
# Crear .env local (NO COMMITEAR)
cp .env.example .env
# Editar .env con tus valores

# Build con docker-compose
docker-compose -f docker-compose.simple.yml build

# Si funciona, el problema está en Coolify/servidor
```

### Logs Útiles

En Coolify, revisa:
1. Build logs completos
2. Memory usage durante el build
3. Disk space en el momento del error

### Solución Alternativa: Nixpacks

Si Docker sigue fallando, Coolify soporta Nixpacks:

1. En Coolify → Settings
2. Cambiar Build Pack: **Nixpacks**
3. Coolify detectará automáticamente Ruby/Rails
4. Deploy

### Contactar Soporte

Si ninguna solución funciona:

1. **Logs completos** del build
2. **Specs del servidor**: `docker info`, `free -h`, `df -h`
3. **Versión de Coolify**
4. **Configuración usada** (docker-compose, variables de entorno)

## Errores Específicos

### "COPY failed: no source files were specified"

**Solución:** Verifica `.dockerignore`, puede estar bloqueando archivos necesarios.

```bash
# Revisar .dockerignore
cat .dockerignore

# Asegurar que estos NO estén bloqueados:
# - Gemfile
# - Gemfile.lock
# - app/
# - config/
# - db/
```

### "bundle install failed"

**Solución:** Problema con Gemfile o red

```bash
# Verificar Gemfile.lock existe
ls -la Gemfile.lock

# En Coolify, añadir variable:
BUNDLE_FROZEN=false
```

### "yaml.h not found" / "psych gem failed"

**Solución:** Falta libyaml-dev

```
checking for yaml.h... no
An error occurred while installing psych (5.2.6)
```

**✅ YA CORREGIDO** en los Dockerfiles actuales. Si usas un Dockerfile viejo:

```dockerfile
# Asegúrate de tener libyaml-dev en la instalación de paquetes
RUN apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libyaml-dev \  # <- Esta línea es crítica
    postgresql-client
```

**Solución rápida:**
```bash
git pull  # Obtén el Dockerfile actualizado
```

### "bootsnap precompile failed"

**Solución:** Problema de permisos o memoria

```bash
# Simplificar Dockerfile, comentar línea:
# RUN bundle exec bootsnap precompile app/ lib/
```

### "Cannot find application"

**Solución:** Entrypoint o CMD incorrectos

```bash
# Verificar en Dockerfile:
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# Y que bin/rails sea ejecutable:
RUN chmod +x bin/rails bin/docker-entrypoint
```

## Checklist de Troubleshooting

- [ ] Servidor tiene suficiente espacio (>10 GB)
- [ ] Servidor tiene suficiente RAM (>2 GB)
- [ ] Variables de entorno configuradas
- [ ] Dockerfile es de una sola etapa
- [ ] `.dockerignore` no bloquea archivos necesarios
- [ ] `bin/docker-entrypoint` es ejecutable
- [ ] Build funciona localmente
- [ ] Caché de Docker limpio

## Testing Rápido

```bash
# Test del Dockerfile localmente
docker build -t test-jombo .

# Si funciona, probar con compose
docker-compose -f docker-compose.simple.yml up

# Verificar health
curl http://localhost:3000/health
```

## Recursos Adicionales

- [Coolify Docs](https://coolify.io/docs)
- [Docker Build Troubleshooting](https://docs.docker.com/engine/reference/builder/)
- [Rails Docker Guide](https://guides.rubyonrails.org/docker.html)
