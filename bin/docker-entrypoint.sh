#!/bin/bash -e

# Borrar el archivo server.pid si existe para evitar que Puma no arranque
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Preparar la base de datos en cada despliegue (create + migrate + setup)
if [[ "$*" == *"rails server"* ]] || [[ "$*" == *"bin/rails server"* ]] || [[ -z "$1" ]]; then
  echo "🚀 Preparando base de datos (db:prepare)..."
  bundle exec rails db:prepare
fi

# Ejecutar el comando principal
exec "$@"
