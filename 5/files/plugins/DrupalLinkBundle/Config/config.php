<?php

/**
 * @file
 */

return [
  'name'        => 'Drupal Link',
  'description' => 'Adds a link to Drupal in the main menu.',
  'author'      => 'Druid',
  'version'     => '1.0.0',

  'menu' => [
    'main' => [
      'drupal.link' => [
        'route'    => 'drupal_link',
        'access'   => 'admin',
        'label'    => 'Manage Content',
        'iconClass' => 'fa-drupal',
        'priority' => 99,
        'linkAttributes' => [
          'target' => '_blank',
        ],
      ],
    ],
  ],

  'routes' => [
    'main' => [
      'drupal_link' => [
        'path'       => '/drupal',
        'controller' => 'MauticPlugin\DrupalLinkBundle\Controller\MenuController::redirectToDrupal',
      ],
    ],
  ],
];
