<?php

declare(strict_types=1);

namespace MauticPlugin\CustomConfigUpdaterBundle\Command;

use Doctrine\ORM\EntityManager;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Command for updating webhook URLs in the Mautic database.
 */
class UpdateConfigCommand extends Command
{
    protected static $defaultName = 'mautic:webhooks:replace';

    public function __construct(private ContainerInterface $container)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Updates Mautic webhook URLs in the database')
            ->setHelp('This command updates webhook URLs in the database, replacing old base URL with a new one')
            ->addOption(
                'source-url',
                null,
                InputOption::VALUE_REQUIRED,
                'The source base URL to replace (e.g., https://old-domain.com)'
            )
            ->addOption(
                'target-url',
                null,
                InputOption::VALUE_REQUIRED,
                'The target base URL to use (e.g., https://new-domain.com)'
            )
            ->addOption(
                'dry-run',
                null,
                InputOption::VALUE_NONE,
                'If set, no actual changes will be made to the database'
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $sourceUrl = $input->getOption('source-url');
        $targetUrl = $input->getOption('target-url');

        if (!$sourceUrl || !$targetUrl) {
            if (!$sourceUrl && !$targetUrl) {
                $this->displayUsage($output);
            } else {
                $output->writeln('<error>Both --source-url and --target-url options are required when using either one.</error>');
            }
            return Command::FAILURE;
        }

        try {
            return $this->updateWebhooks(
                rtrim($sourceUrl, '/'),
                rtrim($targetUrl, '/'),
                (bool) $input->getOption('dry-run'),
                $output
            );
        } catch (\Exception $e) {
            $output->writeln(sprintf('<error>Error updating webhooks: %s</error>', $e->getMessage()));
            return Command::FAILURE;
        }
    }

    private function displayUsage(OutputInterface $output): void
    {
        $output->writeln([
            '<info>This command updates webhook URLs in the database.</info>',
            '',
            'Usage:',
            '  mautic:webhooks:replace --source-url=<old-url> --target-url=<new-url> [--dry-run]',
            '',
            'Example:',
            '  mautic:webhooks:replace --source-url=https://old-domain.com --target-url=https://new-domain.com',
            '',
            'Options:',
            '  --source-url   The source base URL to replace (e.g., https://old-domain.com)',
            '  --target-url   The target base URL to use (e.g., https://new-domain.com)',
            '  --dry-run      If set, no actual changes will be made to the database',
        ]);
    }

    private function updateWebhooks(string $sourceUrl, string $targetUrl, bool $dryRun, OutputInterface $output): int
    {
        /** @var EntityManager $em */
        $em = $this->container->get('doctrine')->getManager();
        $webhooks = $em->getConnection()->fetchAllAssociative('SELECT id, webhook_url FROM ' . MAUTIC_TABLE_PREFIX . 'webhooks');
        $updatedCount = 0;

        foreach ($webhooks as $webhook) {
            if (str_starts_with($webhook['webhook_url'], $sourceUrl)) {
                $newUrl = str_replace($sourceUrl, $targetUrl, $webhook['webhook_url']);
                
                $output->writeln(sprintf(
                    '<info>Webhook ID %d:</info> %s → %s',
                    $webhook['id'],
                    $webhook['webhook_url'],
                    $newUrl
                ));

                if (!$dryRun) {
                    $em->getConnection()->executeUpdate(
                        'UPDATE ' . MAUTIC_TABLE_PREFIX . 'webhooks SET webhook_url = ? WHERE id = ?',
                        [$newUrl, $webhook['id']]
                    );
                    $updatedCount++;
                }
            }
        }

        $output->writeln(sprintf(
            "\n<%s>%s</%s>",
            $dryRun ? 'comment' : 'info',
            $dryRun ? 'DRY RUN - No changes were made to the database' : sprintf('Successfully updated %d webhook(s)', $updatedCount),
            $dryRun ? 'comment' : 'info'
        ));

        return Command::SUCCESS;
    }
}
