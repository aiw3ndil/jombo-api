# API de Reservas de Viajes (Bookings)

## Descripción
Sistema de reservas de viajes que permite a los usuarios reservar asientos en viajes. Las reservas requieren confirmación del conductor antes de ser finalizadas.

## Modelo de Datos

### Booking
- `user_id`: ID del usuario que hace la reserva (pasajero)
- `trip_id`: ID del viaje reservado
- `seats`: Número de asientos reservados (por defecto 1)
- `status`: Estado de la reserva (`pending`, `confirmed`, `rejected`, `cancelled`)

## Estados de la Reserva

- **pending**: Reserva creada por el pasajero, esperando confirmación del conductor. Los asientos NO están descontados.
- **confirmed**: Reserva aprobada por el conductor. Los asientos están descontados del viaje.
- **rejected**: Reserva rechazada por el conductor.
- **cancelled**: Reserva cancelada por el pasajero. Si estaba confirmada, los asientos se devuelven.

## Transiciones de Estado Permitidas

- `pending` → `confirmed` (solo conductor)
- `pending` → `rejected` (solo conductor)
- `pending` → `cancelled` (solo pasajero)
- `confirmed` → `cancelled` (solo pasajero, devuelve asientos)
- `rejected` → **NO puede cambiar**
- `cancelled` → **NO puede cambiar**

## Endpoints para Pasajeros

### 1. Listar mis reservas
**GET** `/api/v1/bookings`

Retorna todas las reservas del usuario autenticado.

**Respuesta:**
```json
[
  {
    "id": 1,
    "user_id": 2,
    "trip_id": 5,
    "seats": 2,
    "status": "pending",
    "created_at": "2025-11-29T14:30:00.000Z",
    "updated_at": "2025-11-29T14:30:00.000Z",
    "trip": {
      "id": 5,
      "departure_location": "Madrid",
      "arrival_location": "Barcelona",
      "departure_time": "2025-12-01T10:00:00.000Z",
      "available_seats": 4,
      "price": "25.50",
      "driver": {
        "id": 1,
        "email": "driver@example.com",
        "name": "Juan Pérez"
      }
    }
  }
]
```

### 2. Ver detalle de una reserva
**GET** `/api/v1/bookings/:id`

Retorna los detalles de una reserva específica.

**Respuesta:** Mismo formato que el listado

### 3. Crear una reserva
**POST** `/api/v1/bookings`

Crea una nueva reserva para un viaje con estado `pending`.

**Body:**
```json
{
  "trip_id": 5,
  "booking": {
    "seats": 2
  }
}
```

**Validaciones:**
- No puedes reservar tu propio viaje (si eres el conductor)
- El número de asientos debe ser mayor a 0

**Respuesta (201 Created):**
```json
{
  "id": 1,
  "user_id": 2,
  "trip_id": 5,
  "seats": 2,
  "status": "pending",
  "created_at": "2025-11-29T14:30:00.000Z",
  "updated_at": "2025-11-29T14:30:00.000Z",
  "trip": { ... }
}
```

**Errores:**
- `404`: Viaje no encontrado
- `422`: Intentas reservar tu propio viaje

**Nota:** Los asientos NO se descuentan hasta que el conductor confirme la reserva.

### 4. Cancelar una reserva
**DELETE** `/api/v1/bookings/:id`

Cancela una reserva. Si la reserva estaba confirmada, devuelve los asientos al viaje.

**Respuesta (200 OK):**
```json
{
  "message": "Booking cancelled successfully"
}
```

## Endpoints para Conductores

### 5. Listar reservas de mi viaje
**GET** `/api/v1/trips/:trip_id/bookings`

Lista todas las reservas de un viaje específico. Solo accesible por el conductor del viaje.

**Respuesta:**
```json
[
  {
    "id": 1,
    "user_id": 2,
    "trip_id": 5,
    "seats": 2,
    "status": "pending",
    "created_at": "2025-11-29T14:30:00.000Z",
    "updated_at": "2025-11-29T14:30:00.000Z",
    "user": {
      "id": 2,
      "email": "passenger@example.com",
      "name": "María García"
    }
  },
  {
    "id": 2,
    "user_id": 3,
    "trip_id": 5,
    "seats": 1,
    "status": "confirmed",
    "created_at": "2025-11-29T13:00:00.000Z",
    "updated_at": "2025-11-29T13:15:00.000Z",
    "user": {
      "id": 3,
      "email": "otro@example.com",
      "name": "Pedro López"
    }
  }
]
```

**Errores:**
- `403 Forbidden`: No eres el conductor de este viaje
- `404 Not Found`: Viaje no encontrado

### 6. Confirmar una reserva
**PATCH** `/api/v1/bookings/:id/confirm`

Confirma una reserva pendiente. Descuenta los asientos del viaje.

**Validaciones:**
- Solo el conductor del viaje puede confirmar
- La reserva debe estar en estado `pending`
- Debe haber suficientes asientos disponibles al momento de confirmar

**Respuesta (200 OK):**
```json
{
  "id": 1,
  "user_id": 2,
  "trip_id": 5,
  "seats": 2,
  "status": "confirmed",
  "created_at": "2025-11-29T14:30:00.000Z",
  "updated_at": "2025-11-29T14:45:00.000Z",
  "trip": {
    "id": 5,
    "departure_location": "Madrid",
    "arrival_location": "Barcelona",
    "available_seats": 2,
    "driver": { ... }
  },
  "user": {
    "id": 2,
    "email": "passenger@example.com",
    "name": "María García"
  }
}
```

**Errores:**
- `403 Forbidden`: No eres el conductor del viaje
- `422 Unprocessable Entity`: No hay suficientes asientos o la reserva no está en pending

### 7. Rechazar una reserva
**PATCH** `/api/v1/bookings/:id/reject`

Rechaza una reserva pendiente.

**Validaciones:**
- Solo el conductor del viaje puede rechazar
- La reserva debe estar en estado `pending`

**Respuesta (200 OK):**
```json
{
  "id": 1,
  "user_id": 2,
  "trip_id": 5,
  "seats": 2,
  "status": "rejected",
  "created_at": "2025-11-29T14:30:00.000Z",
  "updated_at": "2025-11-29T14:45:00.000Z"
}
```

**Errores:**
- `403 Forbidden`: No eres el conductor del viaje
- `422 Unprocessable Entity`: La reserva no se puede rechazar

## Lógica de Negocio

### Flujo de Reserva Completo

1. **Pasajero crea reserva** (POST /api/v1/bookings)
   - Estado: `pending`
   - Asientos del viaje: **NO se descuentan**
   - Validación: No puedes reservar tu propio viaje

2. **Conductor revisa reservas** (GET /api/v1/trips/:trip_id/bookings)
   - Ve todas las reservas: pending, confirmed, rejected, cancelled
   - Decide si confirmar o rechazar cada reserva pendiente

3. **Conductor confirma reserva** (PATCH /api/v1/bookings/:id/confirm)
   - Estado: `pending` → `confirmed`
   - Asientos del viaje: **Se descuentan** en este momento
   - Validación: Debe haber suficientes asientos disponibles

4. **O Conductor rechaza reserva** (PATCH /api/v1/bookings/:id/reject)
   - Estado: `pending` → `rejected`
   - Asientos: No se afectan (nunca se descontaron)

5. **Pasajero puede cancelar** (DELETE /api/v1/bookings/:id)
   - Si está `pending`: Cambia a `cancelled`, no afecta asientos
   - Si está `confirmed`: Cambia a `cancelled` y **devuelve asientos** al viaje
   - Si está `rejected` o `cancelled`: Error, no se puede cancelar

### Gestión de Asientos

- **Al crear**: NO se descuentan asientos
- **Al confirmar**: Se descuentan asientos del viaje (valida disponibilidad)
- **Al rechazar**: No se afectan asientos (nunca se descontaron)
- **Al cancelar pending**: No se afectan asientos
- **Al cancelar confirmed**: Se devuelven asientos al viaje

### Relaciones

- Un usuario puede tener múltiples reservas
- Un viaje puede tener múltiples reservas
- Un usuario puede acceder a sus viajes reservados mediante `booked_trips`
- Un viaje puede acceder a sus pasajeros mediante `passengers`

## Autenticación

Todos los endpoints requieren autenticación mediante token JWT en las cookies.

## Códigos de Error

- `401 Unauthorized`: No autenticado
- `403 Forbidden`: No tienes permisos (no eres el dueño de la reserva o el conductor del viaje)
- `404 Not Found`: Reserva o viaje no encontrado
- `422 Unprocessable Entity`: Datos inválidos o lógica de negocio violada

## Ejemplos de Uso

### Ejemplo 1: Flujo exitoso completo
```bash
# 1. Pasajero crea reserva
POST /api/v1/bookings
Body: { "trip_id": 5, "booking": { "seats": 2 } }
Response: { "status": "pending", ... }

# 2. Conductor ve reservas de su viaje
GET /api/v1/trips/5/bookings
Response: [ { "id": 1, "status": "pending", "user": {...} } ]

# 3. Conductor confirma la reserva
PATCH /api/v1/bookings/1/confirm
Response: { "status": "confirmed", ... }
```

### Ejemplo 2: Pasajero cancela antes de confirmación
```bash
# 1. Pasajero crea reserva
POST /api/v1/bookings
Response: { "id": 1, "status": "pending" }

# 2. Pasajero cambia de opinión y cancela
DELETE /api/v1/bookings/1
Response: { "message": "Booking cancelled successfully" }
# Los asientos NO se afectan porque nunca se descontaron
```

### Ejemplo 3: Conductor rechaza reserva
```bash
# 1. Pasajero crea reserva
POST /api/v1/bookings
Response: { "id": 1, "status": "pending" }

# 2. Conductor rechaza
PATCH /api/v1/bookings/1/reject
Response: { "status": "rejected" }
```

