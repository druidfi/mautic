<?php

/**
 * @see https://github.com/mautic/docker-mautic/blob/main/common/templates/local.php
 */
$container->setParameter('mautic.db_host', getenv('MAUTIC_DB_HOST') ?? 'db');
$container->setParameter('mautic.db_port', getenv('MAUTIC_DB_PORT') ?? 3306);
$container->setParameter('mautic.db_name', getenv('MAUTIC_DB_DATABASE') ?? 'mautic');
$container->setParameter('mautic.db_user', getenv('MAUTIC_DB_USER') ?? 'mautic');
$container->setParameter('mautic.db_password', getenv('MAUTIC_DB_PASSWORD') ?? 'mautic');
