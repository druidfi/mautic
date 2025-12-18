<?php

$trusted_proxies = getenv('MAUTIC_TRUSTED_PROXIES') ?? '';
$trusted_proxies = explode(',', $trusted_proxies) ?? [];

$parameters = [
    'db_host' => getenv('MAUTIC_DB_HOST') ?? 'db',
    'db_port' => getenv('MAUTIC_DB_PORT') ?? 3306,
    'db_name' => getenv('MAUTIC_DB_DATABASE') ?? 'mautic',
    'db_user' => getenv('MAUTIC_DB_USER') ?? 'mautic',
    'db_password' => getenv('MAUTIC_DB_PASSWORD') ?? 'mautic',
    'trusted_proxies' => $trusted_proxies,
];
