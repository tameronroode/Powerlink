FROM php:8.2-fpm
RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev && \
    docker-php-ext-install pdo pdo_pgsql zip
WORKDIR /var/www/html
COPY . .
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist \
 && php artisan config:cache \
 && php artisan route:cache
EXPOSE 8080
CMD ["sh","-c","php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8080}"]
