#syntax=docker/dockerfile:1

# Base Mautic image
FROM mautic_upstream AS mautic_base_5

# DXP variant
FROM mautic_base_5 AS mautic_dxp_5

COPY 5/files/ /var/www/html/docroot/

RUN chown -R www-data:www-data /var/www/html/var

