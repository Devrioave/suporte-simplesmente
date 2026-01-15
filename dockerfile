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
# ... (mantenha o início igual)

# Ajusta permissões de forma recursiva e garante que a pasta public exista
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public

# Corrija o COPY (certifique-se de que o nome do arquivo local é nginx.conf)
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 80

# Script de inicialização sênior: 
# 1. Limpa caches antigos (evita carregar caminhos de diretórios locais)
# 2. Inicia o PHP-FPM em background (-D)
# 3. Inicia o Nginx em foreground (daemon off) para o Docker monitorar
CMD sh -c "php artisan config:clear && php artisan route:clear && php-fpm -D && nginx -g 'daemon off;'"