# Sistema de Reviews - Jombo API

## Descripción General

El sistema de reviews permite a los usuarios (conductores y pasajeros) valorar su experiencia después de cada viaje confirmado. Cada usuario puede dejar una review con una puntuación del 1 al 5 y un comentario opcional.

## Modelo de Datos

### Review Model
```ruby
- booking_id (references bookings)
- reviewer_id (references users) - quien hace la review
- reviewee_id (references users) - quien recibe la review
- rating (integer, 1-5, required)
- comment (text, optional)
- timestamps
```

### Relaciones
- Un `Booking` puede tener múltiples `Review` (una por cada participante)
- Un `User` puede dar muchas reviews (reviews_given)
- Un `User` puede recibir muchas reviews (reviews_received)

### Validaciones
- Rating debe ser entre 1 y 5
- Solo usuarios que participaron en el booking pueden hacer reviews (conductor o pasajero)
- No puedes hacer review de ti mismo
- Solo puedes hacer una review por booking
- Solo se pueden hacer reviews de bookings confirmados
- **Solo se puede hacer review después de que haya pasado el departure_time del viaje**

## API Endpoints

### 1. Crear Review
```http
POST /api/v1/bookings/:booking_id/reviews
```

**Headers:**
- Cookie: jwt={token}

**Body:**
```json
{
  "review": {
    "rating": 5,
    "comment": "Excelente conductor, muy puntual y amable"
  }
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 1,
  "booking_id": 123,
  "reviewer_id": 1,
  "reviewee_id": 2,
  "rating": 5,
  "comment": "Excelente conductor, muy puntual y amable",
  "created_at": "2025-12-02T18:30:00Z",
  "updated_at": "2025-12-02T18:30:00Z",
  "reviewer": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com"
  },
  "reviewee": {
    "id": 2,
    "name": "María García",
    "email": "maria@example.com"
  }
}
```

**Errores:**
- `401 Unauthorized` - No autenticado
- `403 Forbidden` - No participaste en este booking
- `404 Not Found` - Booking no encontrado
- `422 Unprocessable Entity` - Validaciones fallidas (ej: el viaje aún no ha ocurrido)

### 2. Ver Reviews de un Usuario
```http
GET /api/v1/users/:user_id/reviews
```

**Headers:**
- Cookie: jwt={token}

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "booking_id": 123,
    "reviewer_id": 1,
    "reviewee_id": 2,
    "rating": 5,
    "comment": "Excelente conductor",
    "created_at": "2025-12-02T18:30:00Z",
    "reviewer": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com"
    }
  }
]
```

### 3. Ver Reviews de un Booking
```http
GET /api/v1/bookings/:booking_id/reviews
```

**Headers:**
- Cookie: jwt={token}

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "rating": 5,
    "comment": "Excelente conductor",
    "reviewer": {
      "id": 1,
      "name": "Juan Pérez",
      "email": "juan@example.com"
    },
    "reviewee": {
      "id": 2,
      "name": "María García",
      "email": "maria@example.com"
    }
  }
]
```

## Métodos de Usuario

### average_rating
Calcula la puntuación promedio de todas las reviews recibidas:
```ruby
user = User.find(1)
user.average_rating # => 4.5
```

### total_reviews
Cuenta el total de reviews recibidas:
```ruby
user.total_reviews # => 10
```

## Flujo de Uso

1. **Booking Confirmado**: Un pasajero reserva un viaje y el conductor lo confirma
2. **Viaje Completado**: Después del viaje, ambos usuarios pueden dejar una review
3. **Crear Review**: 
   - El pasajero puede hacer review del conductor
   - El conductor puede hacer review del pasajero
4. **Visualizar Reviews**: Las reviews aparecen en el perfil del usuario

## Reglas de Negocio

- ✅ Solo bookings con status "confirmed" pueden ser revieweados
- ✅ Cada usuario puede dejar solo una review por booking
- ✅ El conductor puede hacer review del pasajero
- ✅ El pasajero puede hacer review del conductor
- ✅ Solo se puede hacer review después de que el viaje haya ocurrido (departure_time ha pasado)
- ❌ No puedes hacer review de ti mismo
- ❌ No puedes hacer review si no participaste en el booking
- ❌ No puedes cambiar una review una vez creada (solo crear nuevas)
- ❌ No puedes hacer review de un viaje que aún no ha ocurrido

## Ejemplo de Uso Completo

```ruby
# 1. Obtener un booking confirmado
booking = Booking.find(123)
# => status: "confirmed"

# 2. El pasajero hace review del conductor
POST /api/v1/bookings/123/reviews
{
  "review": {
    "rating": 5,
    "comment": "Muy buen conductor"
  }
}

# 3. El conductor hace review del pasajero
# (usando el mismo endpoint con el token del conductor)
POST /api/v1/bookings/123/reviews
{
  "review": {
    "rating": 4,
    "comment": "Pasajero puntual"
  }
}

# 4. Ver reviews del conductor
GET /api/v1/users/2/reviews

# 5. Ver el rating promedio del conductor
user = User.find(2)
user.average_rating # => 4.67
user.total_reviews # => 15
```

## Notas de Implementación

- Las reviews se relacionan con bookings, no directamente con trips
- Esto permite que múltiples pasajeros en un mismo trip dejen reviews independientes
- El sistema detecta automáticamente quién es el reviewee basado en el reviewer:
  - Si el reviewer es el conductor → reviewee es el pasajero
  - Si el reviewer es el pasajero → reviewee es el conductor
