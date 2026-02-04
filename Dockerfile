#syntax=docker/dockerfile:1

# Base Mautic image v5
FROM mautic_upstream AS mautic_base_5

RUN apt-get update && apt-get install -y \
    libavif15 \
    libxpm4 \
    libwebp7 \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=www-data:www-data 5/local.php /var/www/html/config/
COPY --chown=www-data:www-data 5/parameters_local.php /var/www/html/config/

# DXP variant v5
FROM mautic_base_5 AS mautic_dxp_5

COPY 5/files/ /var/www/html/docroot/

RUN chown -R www-data:www-data /var/www/html/var

# Base Mautic image v6
FROM mautic_upstream AS mautic_base_6

RUN apt-get update && apt-get install -y \
    libavif15 \
    libxpm4 \
    libwebp7 \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=www-data:www-data 5/local.php /var/www/html/config/
COPY --chown=www-data:www-data 5/parameters_local.php /var/www/html/config/

# Base Mautic image v7
FROM mautic_upstream AS mautic_base_7

RUN apt-get update && apt-get install -y \
    libavif15 \
    libxpm4 \
    libwebp7 \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=www-data:www-data 5/local.php /var/www/html/config/
COPY --chown=www-data:www-data 5/parameters_local.php /var/www/html/config/

# DXP variant v7
FROM mautic_base_7 AS mautic_dxp_7

COPY 7/files/ /var/www/html/docroot/

RUN chown -R www-data:www-data /var/www/html/var
