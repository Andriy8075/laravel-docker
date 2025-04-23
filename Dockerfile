FROM php:8.2-apache

# Додайте Node.js (v18) та NPM
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev zip unzip git curl \
    default-mysql-client libzip-dev gnupg
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Встановіть PHP-розширення та Composer
RUN docker-php-ext-install pdo pdo_mysql mysqli mbstring exif pcntl bcmath gd zip
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Налаштування Apache
WORKDIR /app
COPY . .
