FROM php:7.4-apache

# Install system dependencies and PHP extensions required by CodeIgniter 3 & SADUCI CBT
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    unzip \
    curl \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) mysqli pdo pdo_mysql gd zip xml \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite & required modules
RUN a2enmod rewrite headers expires

# CBT optimized php.ini configurations
RUN echo "upload_max_filesize = 128M" > /usr/local/etc/php/conf.d/cbt.ini \
    && echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/cbt.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/cbt.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/cbt.ini \
    && echo "max_input_vars = 10000" >> /usr/local/etc/php/conf.d/cbt.ini \
    && echo "date.timezone = Asia/Jakarta" >> /usr/local/etc/php/conf.d/cbt.ini

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Create required writable directories & set permissions
RUN mkdir -p /var/www/html/uploads \
    /var/www/html/backups \
    /var/www/html/application/logs \
    /var/www/html/application/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/uploads /var/www/html/backups /var/www/html/application/logs /var/www/html/application/cache

EXPOSE 80
CMD ["apache2-foreground"]

