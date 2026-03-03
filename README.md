# Jombo API - Carpooling Platform

API REST para plataforma de carpooling desarrollada con Ruby on Rails.

## 🚗 Descripción

Jombo es una plataforma que conecta conductores y pasajeros para compartir viajes, reducir costos y contribuir al medio ambiente.

## 📚 Documentación

### Deployment

- **[COOLIFY.md](COOLIFY.md)** - 🚀 Guía rápida de deployment con Coolify (5 minutos)
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - 📖 Guía completa de deployment y operaciones

### Autenticación

- **[OAUTH_AUTHENTICATION.md](OAUTH_AUTHENTICATION.md)** - 🔐 Login con Google y Facebook

### API Endpoints

- **[BOOKINGS_API.md](BOOKINGS_API.md)** - Sistema de reservas de viajes
  - Creación de reservas
  - Confirmación por conductor
  - Gestión de estados (pending, confirmed, rejected, cancelled)
  - Endpoints para pasajeros y conductores

- **[REVIEWS_SYSTEM.md](REVIEWS_SYSTEM.md)** - Sistema de reviews y valoraciones
  - Valoraciones de 1-5 estrellas
  - Reviews bidireccionales (conductor ↔ pasajero)
  - Ratings promedio por usuario
  - Solo después del viaje completado

### Sistemas

- **[EMAIL_SYSTEM.md](EMAIL_SYSTEM.md)** - Sistema de correos electrónicos
  - Soporte multiidioma (English, Español, Suomi)
  - Plantillas HTML y texto plano
  - Email de bienvenida
  - Notificaciones de reservas
  - Configuración de proveedores SMTP

- **[MESSAGING_SYSTEM.md](MESSAGING_SYSTEM.md)** - Sistema de mensajería
  - Chat entre conductor y pasajeros
  - Conversaciones por viaje
  - Acceso solo con reserva confirmada
  - Gestión de mensajes y conversaciones

- **[NOTIFICATIONS_SYSTEM.md](NOTIFICATIONS_SYSTEM.md)** - Sistema de notificaciones

## 🌟 Características

- ✅ Autenticación JWT con cookies
- ✅ **Login con Google y Facebook** 🆕
- ✅ Gestión de viajes (CRUD)
- ✅ Sistema de reservas con confirmación del conductor
- ✅ Sistema de reviews y valoraciones (1-5 estrellas)
- ✅ Emails multiidioma (en, es, fi)
- ✅ Búsqueda de viajes por ubicación
- ✅ Control de asientos disponibles
- ✅ Estados de reserva (pending, confirmed, rejected, cancelled)
- ✅ Sistema de mensajería entre conductor y pasajeros
- ✅ Conversaciones por viaje con acceso controlado
- ✅ Perfil de usuario con foto
- ✅ Health checks para monitoreo
- ✅ Docker y Coolify ready

## 🛠 Tecnologías

- **Ruby** 3.x
- **Rails** 7.1
- **PostgreSQL**
- **JWT** para autenticación
- **Action Mailer** para emails
- **I18n** para internacionalización

## 🚀 Instalación

```bash
# Clonar repositorio
git clone <repository-url>
cd jombo-api

# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create db:migrate

# Iniciar servidor
rails server
```

## 🌍 Idiomas Soportados

- **English (en)** - Idioma por defecto
- **Español (es)**
- **Suomi (fi)**

Los usuarios pueden configurar su idioma preferido y recibirán emails en ese idioma.

## 📧 Configuración de Email

### Desarrollo
Los emails se abren automáticamente en el navegador usando `letter_opener`.

```ruby
# Gemfile
gem 'letter_opener', group: :development
```

### Producción
Configurar variables de entorno para SMTP:
- `SMTP_ADDRESS`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`

## 📋 Endpoints Principales

### Autenticación
- `POST /api/v1/register` - Registrar usuario
- `POST /api/v1/login` - Iniciar sesión
- `DELETE /api/v1/logout` - Cerrar sesión
- `GET /api/v1/me` - Obtener usuario actual
- `POST /api/v1/auth/google` - Login con Google 🆕
- `POST /api/v1/auth/facebook` - Login con Facebook 🆕

### Viajes (Trips)
- `GET /api/v1/trips` - Listar viajes (soporta filtros `departure_location`, `arrival_location`, `region`)
- `GET /api/v1/trips/search` - Búsqueda avanzada de viajes
- `GET /api/v1/trips/:departure_location-:arrival_location` - Ruta SEO para búsqueda (ej: `/helsinki-tampere`)
- `GET /api/v1/trips/my_trips` - Mis viajes como conductor
- `POST /api/v1/trips` - Crear viaje
- `GET /api/v1/trips/:id` - Ver detalle de viaje
- `PATCH /api/v1/trips/:id` - Actualizar viaje
- `DELETE /api/v1/trips/:id` - Eliminar viaje

> **Nota sobre el formato de respuesta:**
> - En **España (es)**: Los endpoints de búsqueda devuelven un **Array** directo de viajes `[...]`.
> - En **Finlandia (fi)**: Devuelven un **Objeto** `{ trips: [...], external_options: [...] }` que incluye alternativas de trenes y buses de la API de Digitransit si no hay viajes locales suficientes.

### Reservas (Bookings)
- `GET /api/v1/bookings` - Mis reservas como pasajero
- `POST /api/v1/bookings` - Crear reserva
- `GET /api/v1/bookings/:id` - Ver detalle de reserva
- `DELETE /api/v1/bookings/:id` - Cancelar reserva
- `PATCH /api/v1/bookings/:id/confirm` - Confirmar reserva (solo conductor)
- `PATCH /api/v1/bookings/:id/reject` - Rechazar reserva (solo conductor)
- `GET /api/v1/trips/:trip_id/bookings` - Ver reservas de un viaje (solo conductor)

### Conversaciones y Mensajes
- `GET /api/v1/conversations` - Listar mis conversaciones
- `GET /api/v1/conversations/:id` - Ver conversación con mensajes
- `GET /api/v1/trips/:trip_id/conversation` - Ver conversación de un viaje
- `DELETE /api/v1/conversations/:id` - Eliminar conversación (solo conductor)
- `GET /api/v1/conversations/:conversation_id/messages` - Listar mensajes
- `POST /api/v1/conversations/:conversation_id/messages` - Enviar mensaje
- `DELETE /api/v1/conversations/:conversation_id/messages/:id` - Eliminar mensaje

### Reviews
- `POST /api/v1/bookings/:booking_id/reviews` - Crear review (después del viaje)
- `GET /api/v1/bookings/:booking_id/reviews` - Ver reviews de un booking
- `GET /api/v1/users/:user_id/reviews` - Ver reviews de un usuario

### Health Checks
- `GET /health` - Estado general de la API
- `GET /health/database` - Estado de la conexión a base de datos

## 🗄 Modelos

### User
- `email` - String, único
- `password_digest` - String (bcrypt)
- `name` - String
- `language` - String (en, es, fi) - Default: 'en'

### Trip
- `departure_location` - String
- `arrival_location` - String
- `departure_time` - DateTime
- `available_seats` - Integer
- `price` - Decimal
- `driver_id` - Referencias a User

### Booking
- `user_id` - Referencias a User (pasajero)
- `trip_id` - Referencias a Trip
- `seats` - Integer, default: 1
- `status` - String (pending, confirmed, rejected, cancelled)

### Conversation
- `trip_id` - Referencias a Trip (único)

### Message
- `conversation_id` - Referencias a Conversation
- `user_id` - Referencias a User (autor)
- `content` - Text, máximo 1000 caracteres

### ConversationParticipant
- `conversation_id` - Referencias a Conversation
- `user_id` - Referencias a User

### Review
- `booking_id` - Referencias a Booking
- `reviewer_id` - Referencias a User (quien hace la review)
- `reviewee_id` - Referencias a User (quien recibe la review)
- `rating` - Integer (1-5)
- `comment` - Text (opcional)

## 🚀 Quick Start

### Desarrollo Local

```bash
# Clonar repositorio
git clone <repository-url>
cd jombo-api

# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create db:migrate

# Iniciar servidor
rails server
```

### Deploy con Docker + Coolify

Ver [COOLIFY.md](COOLIFY.md) para guía rápida de deployment (5 minutos).

```bash
# Con docker-compose
docker-compose up -d

# La app estará disponible en http://localhost:3000
```

## 🔐 Autenticación

La API usa JWT con cookies HttpOnly para autenticación segura.

```bash
# Registrar usuario
POST /api/v1/register
{
  "user": {
    "email": "user@example.com",
    "password": "password",
    "password_confirmation": "password",
    "name": "John Doe",
    "language": "en"
  }
}
```

## 🤝 Flujo de Reserva

1. **Pasajero** crea una reserva → Estado: `pending`
2. **Conductor** recibe notificación por email
3. **Conductor** revisa y confirma/rechaza la reserva
4. **Pasajero** recibe confirmación por email
5. Los asientos se descuentan solo cuando se confirma

## 📝 Licencia

Este proyecto está bajo licencia MIT.

## 👥 Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.
