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

# Optional: authenticate Composer's GitHub API calls to raise the unauthenticated 60 req/hour
# rate limit to 5000/hour. Safe to leave unset -- Composer just falls back to anonymous requests.
# Pass at build time with, e.g.: GITHUB_TOKEN=ghp_xxx make bake
RUN --mount=type=secret,id=github_token \
    (test -s /run/secrets/github_token && composer config -g github-oauth.github.com "$(cat /run/secrets/github_token)") || true

# Install third-party plugins via Composer
RUN composer require --no-interaction --no-progress --no-scripts \
    firemultimedia/mautic-multi-captcha-bundle

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

# Do HOTFIX updates with Composer
RUN composer update --no-interaction --no-progress --no-scripts \
    guzzlehttp/guzzle \
    phpoffice/phpspreadsheet \
    studio-42/elfinder

#RUN composer config --json audit.ignore '["PKSA-fy2t-3c5f-827y", "PKSA-qxvb-2bpp-dnk6"]'
RUN composer audit --no-dev --abandoned=ignore || true

#
# DXP variant v7.1
#
FROM mautic_base_71 AS mautic_dxp_71

COPY --chown=www-data:www-data files/shared/dxp/favicon.ico /var/www/html/docroot/app/assets/images/favicon.ico
COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/bundles/CoreBundle/Assets/images/

#
# Base Mautic image v7.2
#
FROM base AS mautic_base_72

# Copy plugins
COPY --chown=www-data:www-data files/7/plugins/DruidXPBundle /var/www/html/docroot/plugins/DruidXPBundle
RUN test -f /var/www/html/docroot/plugins/DruidXPBundle/DruidXPBundle.php

RUN composer audit --no-dev --abandoned=ignore

#
# DXP variant v7.2
#
FROM mautic_base_72 AS mautic_dxp_72

COPY --chown=www-data:www-data files/shared/dxp/favicon.ico /var/www/html/docroot/app/assets/images/favicon.ico
COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/bundles/CoreBundle/Assets/images/
