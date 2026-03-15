#!/bin/bash -e

# Fix permissions
chown -R rails:rails /app/storage /app/tmp /app/log 2>/dev/null || true

# Si no hay argumentos, por defecto arranca el servidor
if [ -z "$1" ]; then
  set -- ./bin/rails server -b 0.0.0.0
fi

if [ "$1" = "./bin/rails" ] && [ "$2" = "server" ]; then
  echo "Preparing database..."
  su -s /bin/bash rails -c "./bin/rails db:prepare"
fi

# Ejecuta el comando principal como el usuario rails
exec su -s /bin/bash rails -c "$*"
