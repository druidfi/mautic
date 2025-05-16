#syntax=docker/dockerfile:1

# Base Mautic image
FROM mautic_upstream AS mautic_base_5

# DXP variant for Mautic 5
FROM mautic_base_5 AS mautic_dxp_5

COPY 5/files/ /var/www/html/docroot/

# Base Mautic 6 image
FROM mautic_upstream AS mautic_base_6

# DXP variant for Mautic 6
FROM mautic_base_6 AS mautic_dxp_6

# Note: When 6/files/ directory is created, uncomment the following line
# COPY 6/files/ /var/www/html/docroot/
