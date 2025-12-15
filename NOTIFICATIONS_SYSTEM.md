# Documentación del Sistema de Notificaciones

Este documento proporciona una descripción general del sistema de notificaciones en la API de Jombo.

## Descripción General

El sistema de notificaciones está diseñado para informar a los usuarios sobre eventos importantes dentro de la aplicación. Se basa en el modelo `Notification`, un `NotificationService` para crear notificaciones y un conjunto de endpoints de API para que los usuarios interactúen con sus notificaciones.

## Modelo (`Notification`)

El núcleo del sistema es el modelo `Notification`, definido en `app/models/notification.rb`.

### Esquema

Una `Notification` tiene los siguientes atributos:

-   `recipient_id`: El ID del usuario que recibe la notificación.
-   `actor_id`: El ID del usuario que generó la notificación.
-   `action`: Una cadena de texto que describe el evento (p. ej., "publicó una nueva reseña").
-   `read_at`: Una marca de tiempo que indica cuándo el usuario leyó la notificación.
-   `notifiable_type`: El tipo del objeto asociado (p. ej., "Trip", "Booking").
-   `notifiable_id`: El ID del objeto asociado.

### Asociaciones

-   `belongs_to :recipient, class_name: 'User'`
-   `belongs_to :actor, class_name: 'User'`
-   `belongs_to :notifiable, polymorphic: true`

## Endpoints de la API

La API permite a los usuarios obtener sus notificaciones y gestionar su estado de lectura. Las rutas están definidas en `config/routes.rb` e implementadas en `app/controllers/api/v1/notifications_controller.rb`.

-   **`GET /api/v1/notifications`**: Obtiene las notificaciones del usuario actual.
-   **`POST /api/v1/notifications/:id/mark_as_read`**: Marca una notificación específica como leída.
-   **`POST /api/v1/notifications/mark_all_as_read`**: Marca todas las notificaciones del usuario actual como leídas.

Las notificaciones no se crean a través de la API; se crean internamente por el sistema.

## Servicio (`NotificationService`)

La lógica de negocio para crear notificaciones está encapsulada en `app/services/notification_service.rb`. Este servicio proporciona una forma centralizada y consistente de generar notificaciones.

### Métodos

-   `create_email_notification(recipient:, actor:, action:, notifiable:)`
-   `create_booking_notification(recipient:, actor:, action:, notifiable:)`
-   `create_message_notification(recipient:, actor:, action:, notifiable:)`

Estos métodos se llaman desde diferentes partes de la aplicación para generar notificaciones.

## Disparadores (Triggers)

Las notificaciones se crean en respuesta a eventos específicos. Una fuente clave de notificaciones es el `UserMailer`.

### Ejemplo: `UserMailer`

En `app/mailers/user_mailer.rb`, se crea una notificación cada vez que se envía un correo electrónico a un usuario. Esto vincula los sistemas de correo y de notificaciones.

```ruby
# app/mailers/user_mailer.rb

def welcome_email(user)
  # ... lógica de envío de correo ...

  NotificationService.new.create_email_notification(
    recipient: user,
    actor: user,
    action: 'welcome_email',
    notifiable: user
  )
end
```

Otras partes de la aplicación utilizan `NotificationService` para crear notificaciones para eventos como nuevos mensajes y confirmaciones de reservas.