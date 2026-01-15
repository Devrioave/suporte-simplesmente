# Estágio 1: Build dos Assets (Vite)
FROM node:20-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio 2: Ambiente de Produção PHP 8.4
FROM php:8.4-fpm-alpine

# Instalação de dependências do sistema
RUN apk add --no-cache nginx libpng-dev libzip-dev zip unzip icu-dev
RUN docker-php-ext-install pdo_mysql gd zip intl bcmath

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
COPY --from=assets /app/public/build ./public/build

# Instalação limpa para produção (Resolve o erro 255 e ServiceProviders)
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Garante permissões de escrita para o Laravel
RUN chown -R www-data:www-data storage bootstrap/cache public

# Configuração do Servidor Web
RUN rm -rf /etc/nginx/http.d/*.conf
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 80

# Inicialização que limpa caches antigos para ler as variáveis da VPS
CMD sh -c "php artisan config:clear && php artisan route:clear && php-fpm -D && nginx -g 'daemon off;'"