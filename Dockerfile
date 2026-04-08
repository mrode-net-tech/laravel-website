FROM serversideup/php:8.5-frankenphp

USER root

# Install Node.js 22 LTS and npm
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Install PHP dependencies (layer caching)
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Install Node dependencies and build frontend assets (layer caching)
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the application
COPY . .

# Run composer scripts now that the full app is present.
# Errors are suppressed because post-autoload-dump (e.g. package discovery)
# may fail when APP_KEY is not set at build time, which is expected.
RUN composer run-script post-autoload-dump --no-interaction 2>/dev/null || true

# Build Vite assets
RUN npm run build

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html

USER www-data

ENV SSL_MODE=off
ENV CADDY_HTTP_PORT=8080
ENV CADDY_SERVER_ROOT=/var/www/html/public
ENV PHP_OPCACHE_ENABLE=1
ENV SHOW_WELCOME_MESSAGE=false
ENV AUTORUN_ENABLED=true
ENV AUTORUN_LARAVEL_MIGRATION=true
ENV AUTORUN_LARAVEL_MIGRATION_TIMEOUT=60

EXPOSE 8080
