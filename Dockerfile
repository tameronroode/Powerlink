FROM php:8.2-fpm

# System deps + PHP extensions
RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev && \
    docker-php-ext-install pdo pdo_pgsql zip

# Workdir
WORKDIR /var/www/html

# Copy code
COPY . .

# Composer (do NOT run artisan cache here!)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Expose (Render sets $PORT)
EXPOSE 8080

# RUNTIME: now env vars exist, so clear caches, run migrations, then serve
CMD ["sh","-c","php artisan config:clear && php artisan cache:clear && php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8080}"]
