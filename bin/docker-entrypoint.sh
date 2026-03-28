#!/bin/bash -e

# Borrar el archivo server.pid si existe para evitar que Puma no arranque
if [ -f /app/tmp/pids/server.pid ]; then
  rm -f /app/tmp/pids/server.pid
fi

# Intentar preparar la base de datos SIEMPRE antes de arrancar
# Esto creará la DB si no existe y correrá las migraciones
echo "🚀 Intentando preparar la base de datos (db:prepare)..."
bundle exec rails db:prepare || echo "⚠️ Advertencia: db:prepare falló, intentando continuar..."

# Ejecuta el comando principal (server, rake, etc.)
echo "🎬 Arrancando aplicación con: $@"
exec "$@"
