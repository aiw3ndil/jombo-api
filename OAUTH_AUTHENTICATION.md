# OAuth Authentication API

## Implementación de Login con Facebook y Google

### Configuración

Antes de usar la autenticación OAuth, debes configurar las siguientes variables de entorno:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=tu_google_client_id

# Facebook OAuth
FACEBOOK_APP_ID=tu_facebook_app_id
FACEBOOK_APP_SECRET=tu_facebook_app_secret
```

### Endpoints

#### Login con Google

**Flujo recomendado (ID Token):**

```http
POST /api/v1/auth/google
Content-Type: application/json

{
  "credential": "google_id_token_jwt_from_frontend"
}
```

**Flujo legacy (Access Token) - También soportado:**

```http
POST /api/v1/auth/google
Content-Type: application/json

{
  "token": "google_access_token_from_frontend"
}
```

**Respuesta exitosa (200 OK):**
```json
{
  "message": "Logged in successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "language": "en",
    "picture_url": "https://..."
  }
}
```

#### Login con Facebook

```http
POST /api/v1/auth/facebook
Content-Type: application/json

{
  "token": "facebook_access_token_from_frontend"
}
```

**Respuesta exitosa (200 OK):**
```json
{
  "message": "Logged in successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "language": "en",
    "picture_url": "https://..."
  }
}
```

### Errores Comunes

**Token inválido (401 Unauthorized):**
```json
{
  "error": "Invalid token"
}
```

**Proveedor inválido (400 Bad Request):**
```json
{
  "error": "Invalid provider"
}
```

**Token no proporcionado (400 Bad Request):**
```json
{
  "error": "Token or credential is required"
}
```

### Flujo de Autenticación

1. **Frontend**: El usuario inicia sesión con Google/Facebook usando sus respectivos SDKs
2. **Frontend**: Obtiene el token de acceso del proveedor OAuth
3. **Frontend**: Envía el token al backend a través de `/api/v1/auth/:provider`
4. **Backend**: Verifica el token con el proveedor OAuth
5. **Backend**: Busca o crea el usuario en la base de datos
6. **Backend**: Genera un JWT y lo guarda en una cookie httpOnly
7. **Backend**: Retorna la información del usuario

### Implementación en Frontend

#### Ejemplo con Google (React) - Flujo Recomendado

```javascript
import { GoogleLogin } from '@react-oauth/google';

function GoogleLoginButton() {
  const handleGoogleLogin = async (credentialResponse) => {
    const response = await fetch('/api/v1/auth/google', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        credential: credentialResponse.credential // ID Token JWT
      }),
      credentials: 'include' // Importante para cookies
    });
    
    const data = await response.json();
    if (response.ok) {
      console.log('Login exitoso:', data.user);
    }
  };

  return (
    <GoogleLogin
      onSuccess={handleGoogleLogin}
      onError={() => console.log('Login Failed')}
    />
  );
}
```

#### Ejemplo con Google (React) - Flujo Legacy con Popup

```javascript
import { useGoogleLogin } from '@react-oauth/google';

function GoogleLoginButton() {
  const login = useGoogleLogin({
    onSuccess: async (tokenResponse) => {
      const response = await fetch('/api/v1/auth/google', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token: tokenResponse.access_token // Access Token
        }),
        credentials: 'include'
      });
      
      const data = await response.json();
      if (response.ok) {
        console.log('Login exitoso:', data.user);
      }
    }
  });

  return <button onClick={() => login()}>Login con Google</button>;
}
```

#### Ejemplo con Facebook (React)

```javascript
import FacebookLogin from 'react-facebook-login';

function FacebookLoginButton() {
  const handleFacebookLogin = async (response) => {
    if (response.accessToken) {
      const apiResponse = await fetch('/api/v1/auth/facebook', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token: response.accessToken
        }),
        credentials: 'include' // Importante para cookies
      });
      
      const data = await apiResponse.json();
      if (apiResponse.ok) {
        console.log('Login exitoso:', data.user);
      }
    }
  };

  return (
    <FacebookLogin
      appId="your_facebook_app_id"
      fields="name,email,picture"
      callback={handleFacebookLogin}
    />
  );
}
```

### Cambios en la Base de Datos

La migración agrega los siguientes campos a la tabla `users`:

- `provider`: String - El proveedor OAuth ('google' o 'facebook')
- `uid`: String - El ID único del usuario en el proveedor OAuth
- Índice único en `[provider, uid]` para prevenir duplicados

### Seguridad

1. **Verificación de tokens**: Todos los tokens son verificados directamente con los proveedores OAuth
2. **Cookies httpOnly**: El JWT se guarda en una cookie httpOnly para prevenir ataques XSS
3. **CORS**: Asegúrate de configurar correctamente CORS en producción
4. **Variables de entorno**: Nunca expongas las credenciales de OAuth en el código

### Notas Importantes

- Los usuarios OAuth no necesitan contraseña, se genera una aleatoria automáticamente
- Si un usuario ya existe con el mismo email pero sin OAuth, se crean como usuarios separados
- La imagen de perfil se descarga y guarda automáticamente en Active Storage
- El idioma por defecto es 'en', pero puede ser actualizado posteriormente

### Testing

Para probar en desarrollo sin configurar OAuth:

1. Puedes comentar temporalmente la verificación de tokens
2. O usar tokens de prueba proporcionados por Google/Facebook
3. Configura las variables de entorno de desarrollo

### Producción

Antes de desplegar:

1. ✅ Configura las variables de entorno en tu servidor
2. ✅ Registra tu aplicación en Google Cloud Console y Facebook Developers
3. ✅ Configura los dominios autorizados en ambos proveedores
4. ✅ Asegúrate de que SSL está habilitado (requerido para OAuth)
5. ✅ Actualiza la configuración de CORS para tu dominio frontend
