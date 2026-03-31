# Sistema de Emails - Jombo

## 🌍 Soporte Multiidioma

El sistema de emails soporta **3 idiomas**:
- **Inglés (en)** - Idioma por defecto
- **Español (es)**
- **Finés (fi)**

Los emails se envían automáticamente en el idioma del usuario configurado en su campo `language`.

## 📧 Emails Configurados

### 1. Email de Bienvenida
**Trigger:** Cuando un usuario se registra
**Template:** `welcome_email`
**Destinatario:** Usuario nuevo
**Contenido:** Bienvenida, descripción de la plataforma, primeros pasos
**Idiomas:** en, es, fi

### 2. Email de Nueva Reserva (para Conductor)
**Trigger:** Cuando un pasajero crea una reserva
**Template:** `booking_received`
**Destinatario:** Conductor del viaje
**Contenido:** Notificación de nueva solicitud pendiente, datos del pasajero, enlace para confirmar/rechazar
**Idiomas:** en, es, fi
**Enlace:** `{FRONTEND_URL}/trips/{trip_id}/bookings`

### 3. Email de Reserva Confirmada (para Pasajero)
**Trigger:** Cuando el conductor confirma una reserva
**Template:** `booking_confirmed`
**Destinatario:** Pasajero que reservó
**Contenido:** Confirmación de reserva, detalles del viaje, datos del conductor
**Idiomas:** en, es, fi

### 4. Email de Cancelación
**Trigger:** Cuando un pasajero cancela su reserva
**Template:** `booking_cancelled`
**Destinatario:** Pasajero que canceló
**Contenido:** Confirmación de cancelación, detalles del viaje cancelado
**Idiomas:** en, es, fi

### 5. Email de Nuevo Mensaje
**Trigger:** Cuando un participante recibe un mensaje en una conversación
**Template:** `new_message`
**Destinatario:** Participantes de la conversación (excepto el remitente)
**Contenido:** Vista previa del mensaje, nombre del remitente, detalles del viaje, enlace para responder
**Idiomas:** en, es, fi
**Enlace:** `{FRONTEND_URL}/trips/{trip_id}/messages`

## 🎨 Plantilla Reutilizable

La plantilla base (`layouts/mailer.html.erb`) sigue la **Guía de Estilo de Email de Jombo**:

- **Header con logo** de Jombo (centrado) y borde superior de acento.
- **Body responsive** con jerarquía clara y diseño mobile-first.
- **Footer** con información legal, enlaces de contacto y opción de baja.
- **Componentes Reutilizables**:
  - `_button.html.erb`: Botones con gradiente de marca y bordes redondeados.
  - `_card.html.erb`: Tarjetas para agrupar información con fondo `#1A1535` y borde `#2D284D`.

### Colores del Brand:
- **Brand Dark**: `#120D2B` (Fondo principal)
- **Brand Cyan**: `#0BB1D3` (Acento primario, enlaces, botones)
- **Brand Purple**: `#9F2FFF` (Acento secundario, gradientes)
- **Brand Blue**: `#5471E9` (Información, fondos de mensajes)
- **Brand Pink**: `#FF419C` (Alertas, errores, rechazos)
- **White**: `#FFFFFF` (Texto principal)

## 📝 Versiones de Email

Cada email tiene **6 versiones** (2 formatos x 3 idiomas):
- **HTML:** Diseño completo con estilos (en, es, fi)
- **Text:** Versión plain text para compatibilidad (en, es, fi)

Rails selecciona automáticamente la versión correcta basándose en:
1. El idioma del usuario (`user.language`)
2. El formato solicitado (HTML o Text)

## 🔧 Uso en Código

### Enviar email con idioma del usuario
```ruby
# El idioma se detecta automáticamente del user.language
UserMailer.welcome_email(user).deliver_later

# Internamente usa:
I18n.with_locale(user.language) do
  # Renderiza el template en el idioma correcto
end
```

### Cambiar el idioma de un usuario
```ruby
# En el registro
user = User.create(
  email: 'user@example.com',
  password: 'password',
  name: 'John',
  language: 'en'  # o 'es', 'fi'
)

# Actualizar idioma
user.update(language: 'es')
```

## 🌐 Archivos de Traducción

### Estructura
```
config/locales/
  ├── mailers.en.yml  # Traducciones en inglés
  ├── mailers.es.yml  # Traducciones en español
  └── mailers.fi.yml  # Traducciones en finés
```

### Plantillas de Email
```
app/views/user_mailer/
  ├── welcome_email.en.html.erb
  ├── welcome_email.es.html.erb
  ├── welcome_email.fi.html.erb
  ├── welcome_email.en.text.erb
  ├── welcome_email.es.text.erb
  ├── welcome_email.fi.text.erb
  └── ... (mismo patrón para otros emails)
```

## ⚙️ Configuración

### Variables de Entorno

```bash
# URL del frontend para enlaces en emails
FRONTEND_URL=http://localhost:3001  # Desarrollo
FRONTEND_URL=https://jombo.com      # Producción
```

### Desarrollo
```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

**Letter Opener:** Los emails se abren automáticamente en el navegador en desarrollo.

Para instalarlo, agregar a Gemfile:
```ruby
gem 'letter_opener', group: :development
```

### Producción
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

## 🔧 Uso en Código

### Enviar email de forma asíncrona (recomendado)
```ruby
UserMailer.welcome_email(user).deliver_later
```

### Enviar email de forma síncrona
```ruby
UserMailer.welcome_email(user).deliver_now
```

### Idiomas Soportados

El sistema valida automáticamente que el idioma sea uno de: `en`, `es`, `fi`

```ruby
# En el modelo User
validates :language, presence: true, inclusion: { in: %w[en es fi] }

# Idioma por defecto: inglés (en)
before_validation :set_default_language, on: :create
```

## 📋 Migración de Usuarios Existentes

Los usuarios existentes al momento de agregar el campo `language` fueron actualizados automáticamente al inglés (`en`) como idioma por defecto.

## 📬 Proveedores de Email Recomendados

- **SendGrid** - 100 emails/día gratis
- **Mailgun** - 5,000 emails/mes gratis
- **AWS SES** - 62,000 emails/mes gratis (si está en EC2)
- **Postmark** - 100 emails/mes gratis

## 🧪 Testing

```ruby
# En tests
mail = UserMailer.welcome_email(user)
assert_equal 'usuario@example.com', mail.to[0]
assert_equal '[Jombo] ¡Bienvenido a Jombo! 🚗', mail.subject
assert_match 'Bienvenido', mail.body.encoded
```

## 📊 Métricas Recomendadas

- Tasa de apertura
- Tasa de click (CTR)
- Tasa de rebote
- Cancelación de suscripción

## 🚀 Mejoras Futuras

- [ ] Email de reseteo de contraseña
- [ ] Email de recordatorio de viaje (24h antes)
- [ ] Email de valoración después del viaje
- [ ] Newsletter periódico
- [ ] Email cuando un viaje está por llenarse
- [ ] Email cuando un viaje es cancelado por el conductor
- [ ] Notificaciones por cambios en el viaje
- [ ] Preferencias de notificación (permitir desactivar ciertos emails)
- [ ] Resumen diario/semanal de actividad
