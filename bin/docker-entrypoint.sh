#!/bin/bash -e

# Forzar el entorno de producción si no está definido
export RAILS_ENV=${RAILS_ENV:-production}
echo "🌍 Entorno actual: $RAILS_ENV"

# Limpieza de PID de Puma
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Intentar preparar la base de datos
echo "🚀 Ejecutando bundle exec rails db:prepare..."
bundle exec rails db:prepare

# Por si acaso db:prepare no corrió las migraciones por estar en desarrollo
echo "migrando base de datos..."
bundle exec rails db:migrate

echo "✅ Base de datos lista. Arrancando servidor..."

# Ejecutar el comando original
exec "$@"
