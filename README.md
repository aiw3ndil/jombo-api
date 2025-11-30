# Jombo API - Carpooling Platform

API REST para plataforma de carpooling desarrollada con Ruby on Rails.

## 🚗 Descripción

Jombo es una plataforma que conecta conductores y pasajeros para compartir viajes, reducir costos y contribuir al medio ambiente.

## 📚 Documentación

### API Endpoints

- **[BOOKINGS_API.md](BOOKINGS_API.md)** - Sistema de reservas de viajes
  - Creación de reservas
  - Confirmación por conductor
  - Gestión de estados (pending, confirmed, rejected, cancelled)
  - Endpoints para pasajeros y conductores

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

## 🌟 Características

- ✅ Autenticación JWT con cookies
- ✅ Gestión de viajes (CRUD)
- ✅ Sistema de reservas con confirmación del conductor
- ✅ Emails multiidioma (en, es, fi)
- ✅ Búsqueda de viajes por ubicación
- ✅ Control de asientos disponibles
- ✅ Estados de reserva (pending, confirmed, rejected, cancelled)
- ✅ Sistema de mensajería entre conductor y pasajeros
- ✅ Conversaciones por viaje con acceso controlado

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

### Viajes
- `GET /api/v1/trips` - Listar todos los viajes
- `GET /api/v1/trips/my_trips` - Mis viajes como conductor
- `GET /api/v1/trips/search/:departure_location` - Buscar viajes
- `POST /api/v1/trips` - Crear viaje
- `GET /api/v1/trips/:id` - Ver detalle de viaje
- `PATCH /api/v1/trips/:id` - Actualizar viaje
- `DELETE /api/v1/trips/:id` - Eliminar viaje

### Reservas
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
