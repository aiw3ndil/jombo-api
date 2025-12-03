#!/bin/bash -e

# Fix permissions for mounted volumes
chown -R rails:rails /app/storage /app/tmp /app/log 2>/dev/null || true
chmod -R 775 /app/storage 2>/dev/null || true

# If running the rails server then create or migrate existing database
if [ "${1}" == "./bin/rails" ] && [ "${2}" == "server" ]; then
  su -s /bin/bash rails -c "./bin/rails db:prepare"
  exec su -s /bin/bash rails -c "$*"
else
  exec su -s /bin/bash rails -c "$*"
fi
