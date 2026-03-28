#!/bin/bash -e

# Borrar el archivo server.pid si existe para evitar que Puma no arranque
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Intentar ejecutar migraciones siempre antes de arrancar.
# Si falla, el contenedor se detendrá y verás el error en los logs de Coolify.
if [[ "$*" == *"rails server"* ]] || [[ "$*" == *"bin/rails server"* ]] || [[ -z "$1" ]]; then
  echo "🚀 Running database migrations..."
  bundle exec rails db:migrate
fi

# Ejecuta el comando principal (server, rake, etc.)
exec "$@"
