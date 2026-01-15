# Estágio 1: Assets
FROM node:20-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio 2: PHP & Nginx
FROM php:8.2-fpm-alpine

RUN apk add --no-cache nginx libpng-dev libzip-dev zip unzip icu-dev
RUN docker-php-ext-install pdo_mysql gd zip intl bcmath

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
COPY --from=assets /app/public/build ./public/build

RUN composer install --no-dev --optimize-autoloader
RUN chown -R www-data:www-data storage bootstrap/cache public

# Copia a configuração que corrigimos no Passo 1
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf

# IMPORTANTE: O Coolify geralmente espera a porta 80 para Nginx
EXPOSE 80

# Script de inicialização corrigido
CMD sh -c "php artisan config:cache && php artisan route:cache && nginx -g 'daemon off;' & php-fpm"