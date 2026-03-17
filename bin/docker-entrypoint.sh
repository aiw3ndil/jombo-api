#!/bin/bash -e

# Si no hay argumentos, por defecto arranca el servidor
if [ -z "$1" ]; then
  set -- ./bin/rails server -b 0.0.0.0
fi

# Si se arranca el servidor, preparamos la base de datos (migraciones)
if [ "$1" = "./bin/rails" ] && [ "$2" = "server" ]; then
  echo "Preparing database..."
  ./bin/rails db:prepare
fi

# Ejecuta el comando principal directamente
# Como el Dockerfile tiene 'USER rails', se ejecuta como ese usuario
exec "$@"
