#!/bin/sh
set -e

echo "🚀 Starting Jombo API deployment..."

# Wait for database to be ready
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h ${DATABASE_HOST:-db} -U ${POSTGRES_USER:-jombo_api}; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Prepare database (create if not exists, run migrations)
echo "🗄️  Preparing database..."
bundle exec rails db:prepare

# Precompile assets if needed (for future frontend)
# echo "🎨 Precompiling assets..."
# bundle exec rails assets:precompile

echo "✅ Deployment preparation complete!"
echo "🌟 Starting Rails server..."

# Start the main process
exec "$@"
