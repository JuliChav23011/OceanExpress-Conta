# Imagen oficial de PHP 8.2.3 con Apache
FROM php:8.2-apache-bookworm
# Instalar dependencias necesarias para PostgreSQL
RUN apt-get update \
    && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*
# Composer copiado desde su imagen oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# Habilitar mod_rewrite para URLs amigables
RUN a2enmod rewrite
# La carpeta public/ será la raíz del sitio web
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
 /etc/apache2/sites-available/*.conf
# Permitir que .htaccess sobrescriba configuración
RUN printf '<Directory /var/www/html/public>\n\
 Options -Indexes +FollowSymLinks\n\
 AllowOverride All\n\
 Require all granted\n\
</Directory>\n' \
 > /etc/apache2/conf-available/z-app.conf \
 && a2enconf z-app
WORKDIR /var/www/html
EXPOSE 80