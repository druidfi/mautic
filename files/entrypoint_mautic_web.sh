#!/bin/bash

source /startup/logger.sh

# Function to check if database has any tables
check_database_empty() {
  local table_count
  table_count=$(mysql -h "${MAUTIC_DB_HOST}" -P "${MAUTIC_DB_PORT}" -u "${MAUTIC_DB_USER}" -p"${MAUTIC_DB_PASSWORD}" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MAUTIC_DB_DATABASE}';" 2>/dev/null)
  if [ "$table_count" = "0" ]; then
    return 0  # Database is empty
  else
    return 1  # Database has tables
  fi
}

# Function to check if Mautic is installed (has site_url configured)
check_mautic_installed() {
  if php -r "include('${MAUTIC_VOLUME_CONFIG}/local.php'); exit(!empty(\$parameters['db_driver']) && !empty(\$parameters['site_url']) ? 0 : 1);"; then
    return 0  # Mautic is installed
  else
    return 1  # Mautic is not installed
  fi
}

# prepare mautic with test data
if [ "$DOCKER_MAUTIC_LOAD_TEST_DATA" = "true" ]; then
  su -s /bin/bash $MAUTIC_WWW_USER -c "php $MAUTIC_CONSOLE doctrine:migrations:sync-metadata-storage"
  # mautic installation with dummy password and email, as the next step (doctrine:fixtures:load) will overwrite those
  su -s /bin/bash $MAUTIC_WWW_USER -c "php $MAUTIC_CONSOLE mautic:install --force --admin_email willchange@mautic.org --admin_password willchange http://localhost"
  su -s /bin/bash $MAUTIC_WWW_USER -c "php $MAUTIC_CONSOLE doctrine:fixtures:load -n"
fi

# Auto-install Mautic if enabled, not installed, and database is empty
if [ "$MAUTIC_AUTO_INSTALL" = "true" ]; then
  if ! check_mautic_installed; then
    if check_database_empty; then
      log "[${DOCKER_MAUTIC_ROLE}]: Auto-install enabled, Mautic not installed, and database is empty. Running mautic:install..."

      # Set defaults for install parameters
      MAUTIC_ADMIN_EMAIL="${MAUTIC_ADMIN_EMAIL:-admin@example.com}"
      MAUTIC_ADMIN_PASSWORD="${MAUTIC_ADMIN_PASSWORD:-adminpassu}"
      MAUTIC_ADMIN_FIRSTNAME="${MAUTIC_ADMIN_FIRSTNAME:-Admin}"
      MAUTIC_ADMIN_LASTNAME="${MAUTIC_ADMIN_LASTNAME:-Administer}"
      MAUTIC_ADMIN_USERNAME="${MAUTIC_ADMIN_USERNAME:-admin}"
      MAUTIC_SITE_URL="${MAUTIC_SITE_URL:-http://localhost}"

      log_debug "MAUTIC_ADMIN_EMAIL=[${MAUTIC_ADMIN_EMAIL}]"
      log_debug "MAUTIC_ADMIN_PASSWORD=[${MAUTIC_ADMIN_PASSWORD}]"
      log_debug "MAUTIC_ADMIN_FIRSTNAME=[${MAUTIC_ADMIN_FIRSTNAME}]"
      log_debug "MAUTIC_ADMIN_LASTNAME=[${MAUTIC_ADMIN_LASTNAME}]"
      log_debug "MAUTIC_ADMIN_USERNAME=[${MAUTIC_ADMIN_USERNAME}]"
      log_debug "MAUTIC_SITE_URL=[${MAUTIC_SITE_URL}]"

      su -s /bin/bash $MAUTIC_WWW_USER -c "php $MAUTIC_CONSOLE mautic:install --force \
        --admin_firstname=${MAUTIC_ADMIN_FIRSTNAME} \
        --admin_lastname=${MAUTIC_ADMIN_LASTNAME} \
        --admin_username=${MAUTIC_ADMIN_USERNAME} \
        --admin_email=${MAUTIC_ADMIN_EMAIL} \
        --admin_password=${MAUTIC_ADMIN_PASSWORD} \
        ${MAUTIC_SITE_URL}"

      log "[${DOCKER_MAUTIC_ROLE}]: Mautic installation completed."
    else
      log "[${DOCKER_MAUTIC_ROLE}]: Auto-install enabled but database has tables. Skipping auto-install."
    fi
  else
    log "[${DOCKER_MAUTIC_ROLE}]: Auto-install enabled but Mautic is already installed. Skipping auto-install."
  fi
fi

# run migrations
if check_mautic_installed; then
  log "[${DOCKER_MAUTIC_ROLE}]: Mautic is already installed, running migrations..."
  su -s /bin/bash $MAUTIC_WWW_USER -c "php $MAUTIC_CONSOLE doctrine:migrations:migrate -n"
else
  log "[${DOCKER_MAUTIC_ROLE}]: Mautic is not installed, skipping migrations."
fi

# start the proper service based on FLAVOUR
if [ "${FLAVOUR}" = "fpm" ]; then \
  php-fpm
elif [ "${FLAVOUR}" = "apache" ]; then \
  apache2-foreground
else
  log "[${DOCKER_MAUTIC_ROLE}]: FLAVOUR variable is not set correctly, exiting."
  exit 1
fi
