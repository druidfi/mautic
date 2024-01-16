<?php

/**
 * @see https://docs.mautic.org/en/5.x/getting_started/how_to_install_mautic.html#installing-with-command-line
 */

$parameters = [
  'db_host' => getenv('DB_HOST') ?? 'db',
  'db_table_prefix' => null,
  'db_port' => (int) getenv('DB_PORT') ?? 3306,
  'db_name' => getenv('DB_NAME') ?? 'mautic-demo',
  'db_user' => getenv('DB_USER') ?? 'mautic-demo',
  'db_password' => getenv('DB_PASSWD') ?? 'mautic-demo',
  'db_backup_tables' => false,
  'db_backup_prefix' => 'bak_',
  'admin_email' => getenv('MAUTIC_ADMIN_USERNAME') ?? 'admin@example.com',
  'admin_password' => getenv('MAUTIC_ADMIN_PASSWORD') ?? 'Maut1cR0cks!',
  'mailer_transport' => null,
  'mailer_host' => 'host.docker.internal',
  'mailer_port' => 1025,
  'mailer_user' => null,
  'mailer_password' => null,
  'mailer_api_key' => null,
  'mailer_encryption' => null,
  'mailer_auth_mode' => null,
  'trusted_proxies' => ['127.0.0.1', 'REMOTE_ADDR'],
];
