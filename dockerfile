# Estágio 1: Assets
FROM node:20-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio 2: PHP 8.4 (Obrigatório para Laravel 12)
FROM php:8.4-fpm-alpine

RUN apk add --no-cache nginx libpng-dev libzip-dev zip unzip icu-dev
RUN docker-php-ext-install pdo_mysql gd zip intl bcmath

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
COPY --from=assets /app/public/build ./public/build

# CORREÇÃO CRÍTICA: Adicionado --no-scripts para evitar erro 255
RUN composer install --no-dev --optimize-autoloader --no-scripts

RUN chown -R www-data:www-data storage bootstrap/cache public

RUN rm -f /etc/nginx/http.d/default.conf
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 80

# No CMD, limpamos o cache para garantir que as variáveis do Coolify sejam lidas
CMD sh -c "php artisan config:clear && php artisan route:clear && php-fpm -D && nginx -g 'daemon off;'"