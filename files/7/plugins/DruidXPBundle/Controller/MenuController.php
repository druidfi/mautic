<?php

namespace MauticPlugin\DruidXPBundle\Controller;

use Mautic\CoreBundle\Controller\CommonController;
use Symfony\Component\HttpFoundation\RedirectResponse;

class MenuController extends CommonController
{
    /**
     * Redirects to the Drupal site.
     *
     * DRUPAL_URL (full URL, e.g. http://localhost:8002) takes precedence over
     * DRUPAL_HOSTNAME, which is always linked with https://.
     */
    public function __invoke(): RedirectResponse
    {
        $drupalUrl = getenv('DRUPAL_URL') ?: sprintf('https://%s', getenv('DRUPAL_HOSTNAME'));

        return new RedirectResponse($drupalUrl);
    }
}
