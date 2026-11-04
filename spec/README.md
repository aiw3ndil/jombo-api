# Test Suite - Jombo API

## 📋 Descripción

Suite completa de tests RSpec para la API de Jombo, cubriendo modelos, controladores (requests) y mailers.

## 🛠 Tecnologías

- **RSpec Rails** (6.1) - Framework de testing
- **FactoryBot** (6.4) - Factories para crear datos de prueba
- **Faker** (3.2) - Generación de datos falsos
- **Shoulda Matchers** (6.0) - Matchers para validaciones y asociaciones

## 📁 Estructura

```
spec/
├── factories/          # Factories de FactoryBot
│   ├── users.rb
│   ├── trips.rb
│   ├── bookings.rb
│   ├── conversations.rb
│   ├── conversation_participants.rb
│   ├── messages.rb
│   └── reviews.rb
├── models/            # Tests de modelos
│   ├── user_spec.rb
│   ├── trip_spec.rb
│   ├── booking_spec.rb
│   ├── conversation_spec.rb
│   ├── message_spec.rb
│   └── review_spec.rb
├── requests/          # Tests de controladores (request specs)
│   ├── sessions_spec.rb
│   ├── registrations_spec.rb
│   ├── trips_spec.rb
│   ├── bookings_spec.rb
│   ├── conversations_spec.rb
│   ├── messages_spec.rb
│   └── reviews_spec.rb
├── mailers/           # Tests de mailers
│   └── user_mailer_spec.rb
├── support/           # Archivos de soporte
│   └── authentication_helper.rb
├── rails_helper.rb    # Configuración de Rails para RSpec
└── spec_helper.rb     # Configuración general de RSpec
```

## 🚀 Ejecutar Tests

### Todos los tests
```bash
bundle exec rspec
```

### Tests específicos por tipo
```bash
# Solo modelos
bundle exec rspec spec/models

# Solo requests (controladores)
bundle exec rspec spec/requests

# Solo mailers
bundle exec rspec spec/mailers
```

### Un archivo específico
```bash
bundle exec rspec spec/models/user_spec.rb
```

### Una línea específica
```bash
bundle exec rspec spec/models/user_spec.rb:15
```

### Con formato de documentación
```bash
bundle exec rspec --format documentation
```

## 📊 Cobertura de Tests

### Modelos (100%)
- ✅ User - Asociaciones, validaciones, métodos personalizados
- ✅ Trip - Asociaciones, validaciones, scopes, métodos
- ✅ Booking - Asociaciones, validaciones, lógica de confirmación/cancelación
- ✅ Conversation - Asociaciones, validaciones, métodos de participantes
- ✅ Message - Asociaciones, validaciones, ordenamiento
- ✅ Review - Asociaciones, validaciones complejas, validaciones personalizadas

### Requests (100%)
- ✅ Sessions - Login/Logout
- ✅ Registrations - Registro de usuarios
- ✅ Trips - CRUD completo
- ✅ Bookings - Crear, confirmar, rechazar, cancelar
- ✅ Conversations - Listar, ver, eliminar
- ✅ Messages - Listar, crear, eliminar
- ✅ Reviews - Crear, listar

### Mailers (100%)
- ✅ Welcome Email - 3 idiomas (en, es, fi)
- ✅ Booking Confirmed - 3 idiomas
- ✅ Booking Received - 3 idiomas
- ✅ Booking Cancelled - 3 idiomas
- ✅ New Message - 3 idiomas

## 🎯 Helpers

### AuthenticationHelper

Proporciona métodos para autenticación en tests de requests:

```ruby
# Genera headers de autenticación
auth_headers(user)

# Hace un request autenticado
authenticated_request(:get, '/api/v1/trips', user, params: {})
```

## 🏭 Factories

### User Factory
```ruby
create(:user)                    # Usuario básico
create(:user, :finnish)          # Usuario en finés
create(:user, :without_phone)    # Usuario sin teléfono
```

### Trip Factory
```ruby
create(:trip)                    # Viaje básico
create(:trip, :full)             # Viaje sin asientos disponibles
create(:trip, :past)             # Viaje en el pasado
create(:trip, :today)            # Viaje hoy
```

### Booking Factory
```ruby
create(:booking)                 # Reserva pendiente
create(:booking, :confirmed)     # Reserva confirmada
create(:booking, :rejected)      # Reserva rechazada
create(:booking, :cancelled)     # Reserva cancelada
```

### Review Factory
```ruby
create(:review, :past_trip)      # Review de viaje pasado
create(:review, :excellent)      # Review con 5 estrellas
create(:review, :poor)           # Review con 1 estrella
```

## 📝 Ejemplo de Test

```ruby
RSpec.describe 'Api::V1::Trips', type: :request do
  let(:user) { create(:user) }
  let(:trip) { create(:trip, driver: user) }

  describe 'GET /api/v1/trips/:id' do
    it 'returns trip details' do
      get "/api/v1/trips/#{trip.id}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(trip.id)
    end
  end
end
```

## 🔧 Configuración

### Base de Datos de Test

```bash
# Crear y migrar base de datos de test
RAILS_ENV=test rails db:create db:migrate

# Limpiar base de datos
RAILS_ENV=test rails db:drop db:create db:migrate
```

### Variables de Entorno

Los tests usan `RAILS_ENV=test` automáticamente. No se requieren variables adicionales.

## 📈 Mejores Prácticas

1. **Usa factories en lugar de fixtures** - Más flexibles y mantenibles
2. **Un assert por test** - Tests más claros y específicos
3. **Nombres descriptivos** - Describe lo que hace el test
4. **Usa contexts** - Agrupa tests relacionados
5. **Usa let para variables** - Lazy loading de objetos
6. **Evita lógica en tests** - Los tests deben ser simples

## 🐛 Debugging

### Ver queries SQL
```ruby
# En cualquier test
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

### Usar binding.pry
```ruby
# Agrega en el test
require 'pry'

it 'does something' do
  binding.pry  # Pausa aquí
  expect(something).to eq(value)
end
```

### Ver errores detallados
```bash
bundle exec rspec --format documentation --backtrace
```

## 📚 Recursos

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [Better Specs](https://www.betterspecs.org/)

## 🤝 Contribuir

Al agregar nuevas funcionalidades:

1. Escribe el test primero (TDD)
2. Asegúrate de que falle
3. Implementa la funcionalidad
4. Verifica que el test pase
5. Refactoriza si es necesario

## ✅ CI/CD

Los tests se ejecutan automáticamente en CI/CD antes de cada deploy.

```yaml
# Ejemplo para GitHub Actions
- name: Run tests
  run: bundle exec rspec
```
