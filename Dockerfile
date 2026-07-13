#syntax=docker/dockerfile:1

FROM mautic_upstream AS base

# Worker defaults (can be overridden via environment variables)
ENV DOCKER_MAUTIC_WORKER_MEMORY_LIMIT=128M \
    DOCKER_MAUTIC_WORKER_TIME_LIMIT=3600

# Fix base image PHP errors
RUN apt-get update && apt-get install -y libavif15 libxpm4 libwebp7 && rm -rf /var/lib/apt/lists/*

# Copy Apache conf
COPY files/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy custom web entrypoint with auto install
COPY files/entrypoint_mautic_web.sh /entrypoint_mautic_web.sh

# Copy custom supervisord configuration
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /var/www/html

# twig/twig pinned <3.28: 3.28.0 breaks Mautic core's OverrideIncludeExtension::includeWithEvent()
# (strict `: string` return type, Twig\Markup returned) -> TypeError on every page render.
# Do HOTFIX updates with Composer
RUN composer update --no-interaction --no-progress --no-scripts \
    symfony/cache \
    symfony/http-client \
    symfony/http-kernel \
    symfony/mailer \
    symfony/mime \
    symfony/monolog-bridge \
    symfony/polyfill-intl-idn \
    symfony/routing \
    symfony/security-http \
    symfony/yaml \
    twig/twig:3.27.1 \
    guzzlehttp/guzzle \
    guzzlehttp/psr7 \
    mtdowling/jmespath.php \
    phpseclib/phpseclib

# Install third-party plugins via Composer
RUN composer require --no-interaction --no-progress --no-scripts \
    firemultimedia/mautic-multi-captcha-bundle

# guzzlehttp/guzzle CVE-2026-55767 and CVE-2026-55568 are fixed only in >=7.12.1, but
# mautic/core-lib pins guzzlehttp/guzzle to ~7.10.0 — nothing we can bump without
# conflicting with Mautic's own dependency constraints. Ignore until Mautic relaxes it.
RUN composer config --json audit.ignore '["CVE-2026-55767", "CVE-2026-55568"]' && \
    composer audit --abandoned=ignore

# NOTE: This must be last step
# Make sure var folder is empty
RUN rm -rf /var/www/html/var && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var /var/www/html/docroot/plugins

#
# Base Mautic image v5
#
FROM base AS mautic_base_5

# Copy plugins
COPY --chown=www-data:www-data files/5/plugins/DruidXPBundle /var/www/html/docroot/plugins/DruidXPBundle
RUN test -f /var/www/html/docroot/plugins/DruidXPBundle/DruidXPBundle.php

#
# Base Mautic image v7
#
FROM base AS mautic_base_7

# Copy plugins
COPY --chown=www-data:www-data files/7/plugins/DruidXPBundle /var/www/html/docroot/plugins/DruidXPBundle
RUN test -f /var/www/html/docroot/plugins/DruidXPBundle/DruidXPBundle.php

#
# DXP variant v5
#
FROM mautic_base_5 AS mautic_dxp_5

COPY --chown=www-data:www-data files/shared/dxp/favicon.ico /var/www/html/docroot/app/assets/images/favicon.ico
COPY --chown=www-data:www-data files/5/app /var/www/html/docroot/app

COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/assets/images/

#
# DXP variant v7
#
FROM mautic_base_7 AS mautic_dxp_7

COPY --chown=www-data:www-data files/shared/dxp/favicon.ico /var/www/html/docroot/app/assets/images/favicon.ico
COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/bundles/CoreBundle/Assets/images/
