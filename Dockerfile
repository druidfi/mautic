ARG PHP_VERSION=8.1
ARG TIMEZONE=Europe/Helsinki

FROM php:${PHP_VERSION}-alpine AS build

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1
ARG MAUTIC_VERSION=5.0.3

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
FROM php:${PHP_VERSION}-fpm-alpine AS mautic-base

ARG TIMEZONE

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY docker/docker-php-entrypoint /usr/local/bin/
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

RUN apk add --no-cache nginx
RUN install-php-extensions apcu imap intl opcache pdo_mysql zip

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN echo 'memory_limit = 512M' >> "$PHP_INI_DIR/php.ini"
RUN echo 'date.timezone="Europe/Helsinki"' >> "$PHP_INI_DIR/php.ini"

EXPOSE 8080

CMD ["nginx"]

#
# NPM install
#
FROM node:20 as npm-build

WORKDIR /app

COPY --from=build /app /app

RUN npx update-browserslist-db@latest
RUN npm install
RUN npm run build

#
# Mautic
#
FROM mautic-base AS mautic

WORKDIR /app

COPY --from=build /app /app
COPY --from=npm-build /app/media/libraries /app/media/libraries
COPY config/local.php /app/config/local.php

RUN mkdir -p /app/config /app/media/files /app/media/images /app/translations /app/var && \
    chown -R www-data:www-data /app/config /app/media /app/translations /app/var
