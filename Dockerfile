FROM php:8.1-alpine AS build

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1
ARG MAUTIC_VERSION=5.0.1

COPY --link --from=composer/composer:2-bin /composer /usr/bin/composer

ADD https://github.com/mautic/mautic/releases/download/${MAUTIC_VERSION}/${MAUTIC_VERSION}.zip /app/mautic.zip

RUN apk add --no-cache npm
RUN unzip -q /app/mautic.zip
RUN rm /app/mautic.zip
RUN composer install --no-dev -n --ignore-platform-reqs --no-scripts --no-progress
RUN npm install
RUN rm -rf config media translations var

#
# PHP-FPM and Nginx
#
FROM php:8.1-fpm-alpine AS mautic-base

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY docker/docker-php-entrypoint /usr/local/bin/
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

RUN apk add --no-cache nginx
RUN install-php-extensions imap intl pdo_mysql zip

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN echo 'memory_limit = 512M' >> "$PHP_INI_DIR/php.ini"
RUN echo 'date.timezone="Europe/Helsinki"' >> "$PHP_INI_DIR/php.ini"

EXPOSE 8080

CMD ["nginx"]

#
# Mautic
#
FROM mautic-base AS mautic

WORKDIR /app

COPY --from=build /app /app
COPY config/local.php /app/config/local.php

RUN mkdir -p /app/config /app/media /app/translations /app/var && \
    chown www-data:www-data /app/config /app/media /app/translations /app/var
