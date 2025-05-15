<?php

namespace MauticPlugin\DrupalLinkBundle\Controller;

use Mautic\CoreBundle\Controller\CommonController;
use Symfony\Component\HttpFoundation\RedirectResponse;

/**
 * Class MenuController.
 */
class MenuController extends CommonController {

  /**
   * Redirects to the Drupal site.
   *
   * @return \Symfony\Component\HttpFoundation\RedirectResponse
   */
  public function redirectToDrupal() {
    $drupalUrl = 'https://druidxp-demo.docker.so';

    return new RedirectResponse($drupalUrl);
  }

}
