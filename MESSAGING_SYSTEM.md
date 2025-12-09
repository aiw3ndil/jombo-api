# Sistema de Mensajería - Jombo

## 💬 Descripción

Sistema de mensajería que permite la comunicación entre conductores y pasajeros después de que una reserva ha sido confirmada. Cada viaje tiene su propio hilo de conversación.

## 🎯 Características

- ✅ Conversación por viaje (un hilo por trip)
- ✅ Acceso solo para participantes con reservas confirmadas
- ✅ Conductor siempre tiene acceso
- ✅ Mensajes en tiempo real (preparado para Action Cable)
- ✅ Eliminación de conversaciones (solo conductor)
- ✅ Eliminación de mensajes individuales (solo autor)
- ✅ Participantes agregados automáticamente al confirmar reserva
- ✅ Notificaciones por email al recibir nuevos mensajes

## 🗄 Modelos

### Conversation
- `trip_id` - Referencia al viaje (único, un viaje = una conversación)
- Relaciones:
  - `belongs_to :trip`
  - `has_many :messages`
  - `has_many :conversation_participants`
  - `has_many :participants` (usuarios)

### Message
- `conversation_id` - Referencia a la conversación
- `user_id` - Referencia al autor del mensaje
- `content` - Texto del mensaje (máximo 1000 caracteres)
- Relaciones:
  - `belongs_to :conversation`
  - `belongs_to :user`

### ConversationParticipant
- `conversation_id` - Referencia a la conversación
- `user_id` - Referencia al participante
- Tabla intermedia para participantes de la conversación

## 🔄 Flujo Automático

1. **Reserva confirmada** → Usuario agregado automáticamente a la conversación
2. **Conversación creada** → Si no existe, se crea al confirmar primera reserva
3. **Conductor y pasajeros** → Agregados como participantes
4. **Acceso verificado** → Solo participantes con reservas confirmadas pueden chatear

## 📋 Endpoints

### Conversaciones

#### Listar mis conversaciones
**GET** `/api/v1/conversations`

Retorna todas las conversaciones donde el usuario es participante.

**Respuesta:**
```json
[
  {
    "id": 1,
    "trip_id": 5,
    "created_at": "2025-11-30T12:00:00.000Z",
    "trip": {
      "id": 5,
      "departure_location": "Madrid",
      "arrival_location": "Barcelona",
      "departure_time": "2025-12-01T10:00:00.000Z",
      "driver": {
        "id": 1,
        "name": "John Driver",
        "email": "driver@example.com"
      }
    },
    "participants": [
      {
        "id": 1,
        "name": "John Driver",
        "email": "driver@example.com"
      },
      {
        "id": 2,
        "name": "Jane Passenger",
        "email": "passenger@example.com"
      }
    ],
    "last_message": {
      "id": 10,
      "content": "See you tomorrow!",
      "created_at": "2025-11-30T15:30:00.000Z",
      "user": {
        "id": 2,
        "name": "Jane Passenger"
      }
    }
  }
]
```

#### Ver conversación específica
**GET** `/api/v1/conversations/:id`

Ver todos los mensajes de una conversación.

**Respuesta:**
```json
{
  "conversation": {
    "id": 1,
    "trip_id": 5,
    "trip": {
      "id": 5,
      "departure_location": "Madrid",
      "arrival_location": "Barcelona",
      "departure_time": "2025-12-01T10:00:00.000Z",
      "driver": { ... }
    },
    "participants": [ ... ]
  },
  "messages": [
    {
      "id": 1,
      "content": "Hi! What time should we meet?",
      "created_at": "2025-11-30T14:00:00.000Z",
      "user": {
        "id": 2,
        "name": "Jane Passenger",
        "email": "passenger@example.com"
      }
    },
    {
      "id": 2,
      "content": "Let's meet at 9:30 AM",
      "created_at": "2025-11-30T14:05:00.000Z",
      "user": {
        "id": 1,
        "name": "John Driver",
        "email": "driver@example.com"
      }
    }
  ]
}
```

#### Ver conversación de un viaje
**GET** `/api/v1/trips/:trip_id/conversation`

Acceder a la conversación de un viaje específico.

**Respuesta:** Igual que GET `/api/v1/conversations/:id`

#### Eliminar conversación
**DELETE** `/api/v1/conversations/:id`

Elimina una conversación completa con todos sus mensajes.

**Restricción:** Solo el conductor del viaje puede eliminar.

**Respuesta:**
```json
{
  "message": "Conversation deleted successfully"
}
```

### Mensajes

#### Listar mensajes de conversación
**GET** `/api/v1/conversations/:conversation_id/messages`

Lista todos los mensajes de una conversación ordenados cronológicamente.

**Respuesta:**
```json
[
  {
    "id": 1,
    "content": "Hi! What time should we meet?",
    "created_at": "2025-11-30T14:00:00.000Z",
    "user": {
      "id": 2,
      "name": "Jane Passenger",
      "email": "passenger@example.com"
    }
  }
]
```

#### Enviar mensaje
**POST** `/api/v1/conversations/:conversation_id/messages`

Envía un mensaje a la conversación.

**Body:**
```json
{
  "message": {
    "content": "Thanks! See you at 9:30"
  }
}
```

**Validaciones:**
- `content` es requerido
- Máximo 1000 caracteres
- Usuario debe ser participante de la conversación

**Respuesta (201 Created):**
```json
{
  "id": 3,
  "content": "Thanks! See you at 9:30",
  "created_at": "2025-11-30T14:10:00.000Z",
  "user": {
    "id": 2,
    "name": "Jane Passenger",
    "email": "passenger@example.com"
  }
}
```

#### Eliminar mensaje
**DELETE** `/api/v1/conversations/:conversation_id/messages/:id`

Elimina un mensaje específico.

**Restricción:** Solo el autor del mensaje puede eliminarlo.

**Respuesta:**
```json
{
  "message": "Message deleted successfully"
}
```

## 🔐 Control de Acceso

### Quién puede acceder a una conversación:

1. **Conductor del viaje** - Siempre tiene acceso
2. **Pasajeros con reserva confirmada** - Solo después de confirmación

### Quién NO puede acceder:

- ❌ Usuarios con reservas pendientes
- ❌ Usuarios con reservas rechazadas
- ❌ Usuarios con reservas canceladas
- ❌ Usuarios sin reserva en el viaje

## 🎨 Casos de Uso

### Caso 1: Primera reserva confirmada
```
1. Conductor crea viaje
2. Pasajero A hace reserva → estado: pending
3. Conductor confirma reserva
   → Se crea conversación automáticamente
   → Conductor y Pasajero A agregados como participantes
4. Ambos pueden chatear
```

### Caso 2: Segunda reserva confirmada
```
1. Conversación ya existe para el viaje
2. Pasajero B hace reserva → estado: pending
3. Conductor confirma reserva
   → Pasajero B agregado a conversación existente
4. Ahora hay 3 participantes: Conductor, Pasajero A, Pasajero B
5. Todos pueden ver todos los mensajes
```

### Caso 3: Pasajero cancela reserva
```
1. Pasajero tiene reserva confirmada → puede chatear
2. Pasajero cancela reserva → estado: cancelled
3. Pasajero YA NO puede acceder a la conversación
4. Mensajes anteriores del pasajero permanecen
```

### Caso 4: Conductor elimina conversación
```
1. Conductor decide limpiar conversación
2. DELETE /api/v1/conversations/:id
3. Se eliminan:
   ✓ Conversación
   ✓ Todos los mensajes
   ✓ Todas las relaciones de participantes
4. Si hay nuevas reservas confirmadas, se crea nueva conversación
```

## 🔧 Configuración Técnica

### Relaciones de Modelos

```ruby
# User
has_many :messages
has_many :conversation_participants
has_many :conversations, through: :conversation_participants

# Trip
has_one :conversation

# Booking
after_update :add_to_conversation, if: :saved_change_to_status?

# Conversation
belongs_to :trip
has_many :messages
has_many :conversation_participants
has_many :participants, through: :conversation_participants
```

### Callbacks Importantes

```ruby
# Booking model
after_update :add_to_conversation, if: :saved_change_to_status?

def add_to_conversation
  if status == 'confirmed'
    conversation = trip.ensure_conversation
    conversation.add_participant(user)
    conversation.add_participant(trip.driver)
  end
end
```

## 📧 Notificaciones por Email

Cada vez que un usuario envía un mensaje, todos los demás participantes de la conversación reciben un email de notificación automáticamente.

### Email de Nuevo Mensaje

**Trigger:** Cuando un participante envía un mensaje en una conversación
**Template:** `new_message`
**Destinatarios:** Todos los participantes excepto el remitente
**Contenido:** 
- Vista previa del mensaje (primeros 100 caracteres)
- Nombre del remitente
- Detalles del viaje
- Enlace directo a la conversación
**Idiomas:** en, es, fi

### Implementación

```ruby
# En Message model
after_create_commit :notify_participants

def notify_participants
  conversation.participants.where.not(id: user_id).find_each do |participant|
    UserMailer.new_message(participant, self).deliver_later
  end
end
```

El email se envía de forma asíncrona para no bloquear la respuesta de la API.

## 🚀 Preparado para WebSockets

El modelo `Message` incluye un callback `after_create_commit` preparado para Action Cable:

```ruby
after_create_commit :broadcast_message

def broadcast_message
  # Listo para implementar Action Cable
  ActionCable.server.broadcast("conversation_#{conversation_id}", {
    message: as_json(include: { user: { only: [:id, :name] } })
  })
end
```

## 📊 Base de Datos

### Índices Creados

```ruby
# conversations
add_index :conversations, :trip_id, unique: true

# messages
add_index :messages, [:conversation_id, :created_at]

# conversation_participants
add_index :conversation_participants, [:conversation_id, :user_id], unique: true
```

## ⚠️ Validaciones

### Conversation
- Un viaje solo puede tener una conversación
- `trip_id` debe ser único

### Message
- `content` requerido
- Máximo 1000 caracteres
- Debe pertenecer a una conversación válida
- Debe tener un autor válido

### ConversationParticipant
- Un usuario no puede ser participante duplicado en la misma conversación
- `user_id` único por `conversation_id`

## 📝 Códigos de Error

- `401 Unauthorized` - No autenticado
- `403 Forbidden` - No tienes acceso a esta conversación/mensaje
- `404 Not Found` - Conversación/mensaje no encontrado
- `422 Unprocessable Entity` - Datos inválidos

## 🔮 Futuras Mejoras

- [ ] Action Cable para mensajes en tiempo real
- [ ] Notificaciones push de nuevos mensajes
- [ ] Indicador de "escribiendo..."
- [ ] Mensajes leídos/no leídos
- [ ] Adjuntar archivos/imágenes
- [ ] Búsqueda de mensajes
- [ ] Archivar conversaciones en lugar de eliminar
- [ ] Silenciar conversaciones
- [ ] Preferencias de notificación (permitir desactivar emails)
- [ ] Resumen diario de mensajes no leídos
