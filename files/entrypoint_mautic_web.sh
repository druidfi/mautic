#!/bin/bash

source /startup/logger.sh

# Force the DB connection to always come from env vars, regardless of what
# was last saved via the Mautic UI (Configuration > System Settings rewrites
# local.php wholesale, baking in whatever host/creds were resolved at save
# time). parameters_local.php is a separate file Mautic's Configurator
# service never reads or writes, and ParameterLoader merges it on top of
# local.php, so this always wins without touching the UI-managed file.
sync_db_config() {
  if [ -z "${MAUTIC_DB_HOST}" ]; then
    log "[${DOCKER_MAUTIC_ROLE}]: MAUTIC_DB_HOST not set, skipping DB config sync."
    return
  fi

  log "[${DOCKER_MAUTIC_ROLE}]: Syncing DB connection into ${MAUTIC_VOLUME_CONFIG}/parameters_local.php from env."
  cat > "${MAUTIC_VOLUME_CONFIG}/parameters_local.php" <<'PHP'
<?php
// Only override a key when its env var is actually set, so a var that
// isn't provided in a given deployment falls back to local.php's value
// instead of getting blanked out.
$parameters = array('db_driver' => 'pdo_mysql');
foreach ([
    'db_host' => 'MAUTIC_DB_HOST',
    'db_port' => 'MAUTIC_DB_PORT',
    'db_name' => 'MAUTIC_DB_DATABASE',
    'db_user' => 'MAUTIC_DB_USER',
    'db_password' => 'MAUTIC_DB_PASSWORD',
] as $key => $envVar) {
    $value = getenv($envVar);
    if (false !== $value && '' !== $value) {
        $parameters[$key] = $value;
    }
}
// CORS — CORSMiddleware reads from this file directly (not from the Symfony DI
// container), so translate the env vars here.
$corsRestrict = getenv('MAUTIC_CORS_RESTRICT_DOMAINS');
if (false !== $corsRestrict && '' !== $corsRestrict) {
    $parameters['cors_restrict_domains'] = filter_var($corsRestrict, FILTER_VALIDATE_BOOLEAN);
}
$corsValidDomains = getenv('MAUTIC_CORS_VALID_DOMAINS');
if (false !== $corsValidDomains && '' !== $corsValidDomains) {
    $decoded = json_decode($corsValidDomains, true);
    if (is_array($decoded)) {
        $parameters['cors_valid_domains'] = $decoded;
    }
}
PHP
  chown "${MAUTIC_WWW_USER}:${MAUTIC_WWW_GROUP}" "${MAUTIC_VOLUME_CONFIG}/parameters_local.php"
}

sync_db_config

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
