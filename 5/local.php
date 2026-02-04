<?php
// These are min values for mautic-docker image entrypoint script to detect if Mautic is installed
$parameters = array(
  'db_driver' => 'pdo_mysql',
  'site_url' => getenv('MAUTIC_SITE_URL'),
);
