<?php

declare(strict_types=1);

namespace MauticPlugin\DruidXPBundle\Command;

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception as DBALException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use const \MAUTIC_TABLE_PREFIX;

#[AsCommand(
    name: 'mautic:webhooks:replace',
    description: 'Updates Mautic webhook URLs in the database',
)]
class UpdateWebhooksCommand extends Command
{
    private const BATCH_SIZE = 100;

    public function __construct(private readonly Connection $connection)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
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
        $io = new SymfonyStyle($input, $output);
        $sourceUrl = $input->getOption('source-url');
        $targetUrl = $input->getOption('target-url');
        $dryRun = (bool) $input->getOption('dry-run');

        if (!$sourceUrl || !$targetUrl) {
            $io->error('Both --source-url and --target-url options are required.');
            $io->section('Command Usage');
            $io->listing([
                'mautic:webhooks:replace --source-url=<old-url> --target-url=<new-url> [--dry-run]',
                '',
                'Example:',
                'mautic:webhooks:replace --source-url=https://old-domain.com --target-url=https://new-domain.com',
            ]);
            return Command::FAILURE;
        }

        // Normalize URLs by removing trailing slashes
        $sourceUrl = rtrim($sourceUrl, '/');
        $targetUrl = rtrim($targetUrl, '/');

        try {
            return $this->updateWebhooks($sourceUrl, $targetUrl, $dryRun, $io);
        } catch (DBALException $e) {
            $io->error(sprintf('Database error: %s', $e->getMessage()));
            return Command::FAILURE;
        } catch (\Exception $e) {
            $io->error(sprintf('Error updating webhooks: %s', $e->getMessage()));
            return Command::FAILURE;
        }
    }

    private function updateWebhooks(string $sourceUrl, string $targetUrl, bool $dryRun, SymfonyStyle $io): int
    {
        $tablePrefix = defined('MAUTIC_TABLE_PREFIX') ? MAUTIC_TABLE_PREFIX : '';
        $webhooksTable = $tablePrefix . 'webhooks';
        $updatedCount = 0;
        $totalCount = 0;

        // Get total count of webhooks for progress display
        $totalWebhooks = (int) $this->connection->fetchOne("SELECT COUNT(id) FROM {$webhooksTable}");

        if ($totalWebhooks === 0) {
            $io->warning('No webhooks found in the database.');
            return Command::SUCCESS;
        }

        $io->title('Webhook URL Update');
        $io->text([
            sprintf('Source URL: <comment>%s</comment>', $sourceUrl),
            sprintf('Target URL: <comment>%s</comment>', $targetUrl),
            sprintf('Dry Run: <comment>%s</comment>', $dryRun ? 'Yes' : 'No'),
        ]);

        $io->progressStart($totalWebhooks);

        // Process webhooks in batches to avoid memory issues with large datasets
        $offset = 0;

        while (true) {
            // Use prepared statement for better security
            $stmt = $this->connection->prepare("SELECT id, webhook_url FROM {$webhooksTable} ORDER BY id LIMIT :limit OFFSET :offset");
            $stmt->bindValue('limit', self::BATCH_SIZE, \PDO::PARAM_INT);
            $stmt->bindValue('offset', $offset, \PDO::PARAM_INT);
            $webhooks = $stmt->executeQuery()->fetchAllAssociative();

            if (empty($webhooks)) {
                break;
            }

            foreach ($webhooks as $webhook) {
                $io->progressAdvance();
                $totalCount++;

                if (str_starts_with($webhook['webhook_url'], $sourceUrl)) {
                    $newUrl = str_replace($sourceUrl, $targetUrl, $webhook['webhook_url']);

                    // Store changes for summary report
                    $changes[] = [
                        'id' => $webhook['id'],
                        'old_url' => $webhook['webhook_url'],
                        'new_url' => $newUrl,
                    ];

                    if (!$dryRun) {
                        // Use prepared statement for the update
                        $this->connection->executeStatement(
                            "UPDATE {$webhooksTable} SET webhook_url = ? WHERE id = ?",
                            [$newUrl, $webhook['id']]
                        );
                        $updatedCount++;
                    }
                }
            }

            $offset += self::BATCH_SIZE;
        }

        $io->progressFinish();

        // Display summary of changes
        if (!empty($changes)) {
            $io->section('Changes Summary');
            $rows = [];

            foreach ($changes as $change) {
                $rows[] = [
                    $change['id'],
                    $change['old_url'],
                    $change['new_url'],
                ];
            }

            $io->table(['ID', 'Old URL', 'New URL'], $rows);
        }

        if ($dryRun) {
            $io->warning(sprintf('DRY RUN - Found %d webhooks that would be updated.', count($changes ?? [])));
        } else {
            $io->success(sprintf('Successfully updated %d webhook(s) out of %d total.', $updatedCount, $totalCount));
        }

        return Command::SUCCESS;
    }
}
