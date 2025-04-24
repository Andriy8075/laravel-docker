# Stage 1: Build Node assets
FROM node:18-alpine AS node-build
WORKDIR /app

# Copy only the necessary files for npm to avoid cache busting
COPY package*.json ./
RUN npm install

# Copy the rest of the app to build assets
COPY . .
RUN npm run build

# Stage 2: Install PHP dependencies with Composer
FROM composer:2 AS php-deps
WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader

# Stage 3: Final production image
FROM php:8.2-fpm-alpine AS production

# Install system dependencies
RUN apk add --no-cache --update \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    mysql-client \
    libzip-dev \
    gnupg \
    autoconf \
    g++ \
    make \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Install Composer manually
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www

# Copy necessary files from composer stage
COPY --from=php-deps /app /var/www

# Copy built assets from node stage
COPY --from=node-build /app/public /var/www/public

# If needed, you can copy the .env and any other config manually
# COPY .env /var/www/.env
# Fix permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
# Clean up
RUN rm -rf /var/cache/apk/* /tmp/*

# Expose port if needed
EXPOSE 9000

CMD ["php-fpm"]
