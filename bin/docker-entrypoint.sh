#!/bin/bash -e

# Borrar el archivo server.pid si existe para evitar que Puma no arranque
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Si el primer argumento es 'server' o se arranca rails
if [[ "$*" == *"rails server"* ]] || [[ "$*" == *"bin/rails server"* ]] || [[ -z "$1" ]]; then
  echo "🚀 Preparamos la base de datos (migraciones)..."
  bundle exec rails db:prepare
fi

# Ejecuta el comando principal
exec "$@"
