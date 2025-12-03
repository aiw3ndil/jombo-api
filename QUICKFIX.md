# 🚨 Fix Rápido - Errores de Build en Coolify

## Errores Comunes

### Error 1: "exporting to image"
```
#20 exporting to image
Error type: RuntimeException
```

### Error 2: "yaml.h not found" / "psych gem failed"
```
checking for yaml.h... no
An error occurred while installing psych (5.2.6)
```

**✅ AMBOS ERRORES SOLUCIONADOS** - Los Dockerfiles ya tienen todas las dependencias.

---

## Solución Rápida (4 pasos)

### ✅ Paso 1: Cambiar Configuración en Coolify

**IMPORTANTE:** En lugar de Docker Compose, usa Dockerfile directo:

1. Ve a tu aplicación en Coolify
2. Settings → General
3. **Build Type**: Cambia a `Dockerfile`
4. **Dockerfile Path**: `./Dockerfile`
5. Guarda

### ✅ Paso 2: Añadir Base de Datos Separada

1. En Coolify, añade un nuevo recurso: **Database → PostgreSQL**
2. Dale un nombre: `jombo-db`
3. Una vez creada, conecta a tu aplicación
4. Coolify generará automáticamente `DATABASE_URL`

### ✅ Paso 3: Configurar Variables de Entorno

En tu aplicación → Environment Variables:

```env
SECRET_KEY_BASE=<genera con: rails secret>
RAILS_MASTER_KEY=<copia de config/master.key>
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
```

**NO necesitas** configurar:
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

Coolify lo hace automáticamente vía `DATABASE_URL`.

### ✅ Paso 4: Deploy

Click **Deploy** de nuevo.

---

## Si Aún Falla

### Opción A: Usar Nixpacks (Más Simple)

1. Settings → Build Pack
2. Selecciona **Nixpacks**
3. Deploy

Nixpacks detecta automáticamente Rails y configura todo.

### Opción B: Usar Dockerfile Simplificado

1. Renombra archivos:
   ```bash
   mv Dockerfile Dockerfile.backup
   mv Dockerfile.simple Dockerfile
   ```

2. Commit y push:
   ```bash
   git add Dockerfile
   git commit -m "Use simplified Dockerfile"
   git push
   ```

3. Deploy en Coolify

---

## Verificación

Después del deploy exitoso:

```bash
curl https://tu-dominio.com/health
```

Deberías ver:
```json
{"status":"ok","version":"1.0.0"}
```

---

## Requisitos del Servidor

Mínimo para que funcione:
- **RAM**: 2 GB
- **Disco**: 10 GB libres
- **CPU**: 2 cores

Verifica en tu servidor:
```bash
free -h  # Ver RAM
df -h    # Ver disco
```

---

## Soporte

Si sigue fallando:
1. Revisa [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Verifica logs completos en Coolify
3. Comprueba recursos del servidor

---

## Alternativa: Railway / Render

Si Coolify sigue dando problemas, estas plataformas funcionan con este proyecto:
- Railway.app (detecta Rails automáticamente)
- Render.com (usa el Dockerfile)
- Fly.io (con `flyctl launch`)

