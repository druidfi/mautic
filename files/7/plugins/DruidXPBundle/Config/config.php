<?php

// The "Manage Content" link is shown when either DRUPAL_URL or DRUPAL_HOSTNAME is set.
$drupalLinkEnabled = getenv('DRUPAL_URL') || getenv('DRUPAL_HOSTNAME');

return [
    'name'        => 'DruidXP Integration',
    'description' => 'This is an example config file for a simple Hello World plugin.',
    'author'      => 'Druid.fi',
    'version'     => '1.0.0',

    'menu' => $drupalLinkEnabled ? [
        'main'  => [
            'priority' => 99,
            'items'    => [
                'druidxp.drupal.link' => [
                    'label'     => 'Manage Content',
                    'iconClass' => 'ri-file-edit-fill',
                    'access'    => 'admin',
                    'route'     => 'druidxp.drupal.link',
                    'linkAttributes' => [
                        'target' => '_blank',
                    ],
                ],
            ],
        ],
    ] : [],

    'routes' => $drupalLinkEnabled ? [
        'main' => [
            'druidxp.drupal.link' => [
                'path'       => '/drupal',
                'controller' => MauticPlugin\DruidXPBundle\Controller\MenuController::class,
            ],
        ],
    ] : [],
];
