<?php

namespace MauticPlugin\DruidXPBundle\Controller;

use Mautic\CoreBundle\Controller\CommonController;
use Symfony\Component\HttpFoundation\RedirectResponse;

class MenuController extends CommonController
{
    /**
     * Redirects to the Drupal site.
     */
    public function __invoke(): RedirectResponse
    {
        $drupalUrl = sprintf('https://%s', getenv('DRUPAL_HOSTNAME'));

        return new RedirectResponse($drupalUrl);
    }
}
