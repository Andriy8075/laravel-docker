# Stage 1: Node builder
FROM node:18-alpine AS node-build
WORKDIR /app
COPY package*.json ./
RUN npm install && npm cache clean --force
COPY . .
RUN npm run build && rm -rf node_modules

# Stage 2: Composer builder
FROM composer:2 AS php-deps
WORKDIR /app
COPY composer.* ./
RUN composer install --no-dev --no-scripts --optimize-autoloader

# Stage 3: Final image
FROM php:8.2-fpm-alpine

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Runtime deps (без dev-пакетів)
RUN apk add --no-cache \
    libpng \
    oniguruma \
    libxml2 \
    mariadb-client \
    libzip \
    nodejs \
    npm

# Build deps (видаляються після встановлення)
RUN apk add --no-cache --virtual .build-deps \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    libzip-dev \
    autoconf \
    g++ \
    make && \
    docker-php-ext-install \
    pdo_mysql \
    mbstring \
    gd \
    zip && \
    apk del .build-deps

WORKDIR /var/www

# Copy only necessary files
COPY --from=php-deps /app/vendor ./vendor
COPY --from=node-build /app/public/build ./public/build
COPY . .

RUN if [ ! -f .env ]; then cp .env.example .env; fi

RUN ls -la
RUN ls -la /var/www

# Fix permissions
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000

CMD ["php-fpm"]
