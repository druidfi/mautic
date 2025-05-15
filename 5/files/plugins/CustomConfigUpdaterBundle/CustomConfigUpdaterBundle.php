<?php

declare(strict_types=1);

namespace MauticPlugin\CustomConfigUpdaterBundle;

use Mautic\PluginBundle\Bundle\PluginBundleBase;
use MauticPlugin\CustomConfigUpdaterBundle\Command\UpdateConfigCommand;
use Symfony\Component\Console\Application;
use Symfony\Component\DependencyInjection\ContainerBuilder;

/**
 * Bundle class for the CustomConfigUpdater plugin.
 */
class CustomConfigUpdaterBundle extends PluginBundleBase
{
    /**
     * {@inheritdoc}
     */
    public function build(ContainerBuilder $container): void
    {
        parent::build($container);
    }

    /**
     * {@inheritdoc}
     */
    public function registerCommands(Application $application): void
    {
        $application->add(new UpdateConfigCommand($application->getKernel()->getContainer()));
    }
}
