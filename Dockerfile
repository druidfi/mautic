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
    phpseclib/phpseclib \
    phpoffice/phpspreadsheet:5.9.0

# Install third-party plugins via Composer
RUN composer require --no-interaction --no-progress --no-scripts \
    firemultimedia/mautic-multi-captcha-bundle

# guzzlehttp/guzzle advisories below are fixed only in >=7.12.1/7.12.3/7.14.2/7.15.1, but
# mautic/core-lib pins guzzlehttp/guzzle to ~7.10.0 — nothing we can bump without
# conflicting with Mautic's own dependency constraints. Ignore until Mautic relaxes it.
RUN composer config --json audit.ignore '["PKSA-fy2t-3c5f-827y", "PKSA-qxvb-2bpp-dnk6", "PKSA-bbs6-q5q9-f3t4", "PKSA-bcdd-5xc7-gwfb", "PKSA-pwsk-hy21-4gby", "CVE-2026-55767", "CVE-2026-55568", "PKSA-gcrk-3vtt-1r14", "PKSA-cnw1-2ytm-cgr8"]' && \
    composer audit --abandoned=ignore

# NOTE: This must be last step
# Make sure var folder is empty
RUN rm -rf /var/www/html/var && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var /var/www/html/docroot/plugins

#
# Base Mautic image v7.1
#
FROM base AS mautic_base_71

# Copy plugins
COPY --chown=www-data:www-data files/7/plugins/DruidXPBundle /var/www/html/docroot/plugins/DruidXPBundle
RUN test -f /var/www/html/docroot/plugins/DruidXPBundle/DruidXPBundle.php

#
# DXP variant v7.1
#
FROM mautic_base_71 AS mautic_dxp_71

COPY --chown=www-data:www-data files/shared/dxp/favicon.ico /var/www/html/docroot/app/assets/images/favicon.ico
COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/bundles/CoreBundle/Assets/images/
