# OAuth Credential Update - Backend

## Cambios Realizados

### Fecha: 2025-12-05

### Problema
El frontend cambió de usar `useGoogleLogin` (popup con access token) a `GoogleLogin` component (ID token JWT con credential). El backend necesitaba soportar el nuevo parámetro `credential` además del legacy `token`.

### Solución Implementada

#### 1. `app/controllers/api/v1/oauth_controller.rb`

**Cambio en el método `create`:**

```ruby
# Antes
token = params[:token]

# Ahora - Soporta ambos flujos
token = params[:credential] || params[:token]
```

**Ventajas:**
- ✅ Retrocompatibilidad: Sigue soportando el flujo con `token`
- ✅ Nuevo flujo: Acepta `credential` del componente GoogleLogin
- ✅ Sin breaking changes: El código existente sigue funcionando

### Flujos Soportados

#### Flujo 1: ID Token (Recomendado) - Nuevo
```json
POST /api/v1/auth/google
{
  "credential": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Validación:**
- El token se valida con `https://oauth2.googleapis.com/tokeninfo?id_token=...`
- Google verifica la firma JWT
- Se extrae `sub` (user ID), `email`, `name`, `picture`

#### Flujo 2: Access Token (Legacy) - Todavía soportado
```json
POST /api/v1/auth/google
{
  "token": "ya29.a0AfB_byC..."
}
```

**Validación:**
- El mismo endpoint de Google también valida access tokens
- Retrocompatibilidad completa

### Archivos Modificados

1. ✅ `app/controllers/api/v1/oauth_controller.rb`
   - Línea 8: Acepta `credential` o `token`
   - Línea 14: Mensaje de error actualizado

2. ✅ `OAUTH_AUTHENTICATION.md`
   - Documentación actualizada con ambos flujos
   - Ejemplos de frontend para ambos métodos

### No Requiere Cambios

- ❌ Gemfile (ya tiene las dependencias necesarias)
- ❌ Routes (ya está configurado)
- ❌ User model (ya tiene `from_omniauth`)
- ❌ Database (ya tiene campos `provider` y `uid`)

### Testing

#### Test Manual

1. **Con credential (nuevo flujo):**
```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"credential": "VALID_GOOGLE_ID_TOKEN"}'
```

2. **Con token (legacy):**
```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"token": "VALID_GOOGLE_ACCESS_TOKEN"}'
```

3. **Sin parámetros (error esperado):**
```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Respuesta esperada:**
```json
{
  "error": "Token or credential is required"
}
```

### Logs para Debugging

El controlador ya tiene logs para debugging:

```ruby
Rails.logger.error "OAuth verification error: #{e.message}"
Rails.logger.error "Google token aud mismatch"
Rails.logger.error "Facebook credentials not configured"
Rails.logger.error "Facebook token verification failed"
Rails.logger.error "Facebook token is invalid"
```

### Variables de Entorno Requeridas

No cambian:

```bash
# .env
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
FACEBOOK_APP_ID=xxx
FACEBOOK_APP_SECRET=xxx
```

### Frontend Compatible

El frontend ahora envía:
- Google: `{ credential: "..." }` (usando `<GoogleLogin />` component)
- Facebook: `{ token: "..." }` (sigue igual)

### Rollback

Si necesitas revertir:

```bash
cd /Users/aiwen/code/jombo-api
git checkout HEAD -- app/controllers/api/v1/oauth_controller.rb
git checkout HEAD -- OAUTH_AUTHENTICATION.md
```

### Next Steps

1. ✅ Backend actualizado
2. ✅ Documentación actualizada
3. ⏳ Probar en desarrollo
4. ⏳ Deployar a producción

### Deployment Checklist

- [ ] Verificar que `GOOGLE_CLIENT_ID` está configurado
- [ ] Hacer commit de los cambios
- [ ] Push a repositorio
- [ ] Deploy a staging
- [ ] Probar OAuth en staging
- [ ] Deploy a producción
- [ ] Monitorear logs

### Beneficios

1. **Mejor Experiencia de Usuario**
   - El flujo con `GoogleLogin` component es más estable
   - No depende de popups que pueden ser bloqueados

2. **Mejor Seguridad**
   - El ID token incluye firma JWT verificada por Google
   - Menos superficie de ataque

3. **Menos Llamadas HTTP**
   - El flujo anterior: Google → Frontend → userinfo API → Backend
   - El flujo nuevo: Google → Frontend → Backend

4. **Retrocompatibilidad**
   - El código legacy sigue funcionando
   - Migración gradual sin downtime

### Referencias

- [Google Identity Documentation](https://developers.google.com/identity/gsi/web/guides/overview)
- [OAuth 2.0 ID Token](https://developers.google.com/identity/protocols/oauth2/openid-connect)
- Frontend: `/Users/aiwen/code/jombo-frontend/GOOGLE_OAUTH_FIX.md`
