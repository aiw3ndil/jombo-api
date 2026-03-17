# syntax = docker/dockerfile:1

# 1. Base compartida
ARG RUBY_VERSION=3.3.7
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /app

# Variables de entorno para producción
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# 2. Etapa de Construcción (Build)
# Aquí se instalan las herramientas necesarias para compilar gemas con extensiones C (como pg o bcrypt)
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    libyaml-dev \
    pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Instalamos las gemas
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copiamos el código de la aplicación
COPY . .

# Precompilamos bootsnap para un arranque más rápido
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# 3. Etapa Final
# Esta es la imagen limpia que se despliega. No tiene compiladores.
FROM base

# Instalamos solo las librerías de tiempo de ejecución (runtime)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libpq5 \
    postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copiamos las gemas y el código desde la etapa de build
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# Creamos el usuario rails para no ejecutar como root
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /app/db /app/log /app/storage /app/tmp

# Permisos para el entrypoint
RUN chmod +x /app/bin/docker-entrypoint.sh

USER rails:rails

EXPOSE 3000
ENTRYPOINT ["/app/bin/docker-entrypoint.sh"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
