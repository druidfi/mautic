#syntax=docker/dockerfile:1

FROM mautic_upstream AS base

# Fix base image PHP errors
RUN apt-get update && apt-get install -y libavif15 libxpm4 libwebp7 && rm -rf /var/lib/apt/lists/*

# Make sure var folder is empty
RUN rm -rf /var/www/html/var && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var

# Copy Apache conf
COPY files/000-default.conf /etc/apache2/sites-available/000-default.conf

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
COPY --chown=www-data:www-data files/shared/dxp/logo* /var/www/html/docroot/app/assets/images/
