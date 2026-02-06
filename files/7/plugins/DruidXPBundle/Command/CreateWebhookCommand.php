<?php

declare(strict_types=1);

namespace MauticPlugin\DruidXPBundle\Command;

use Doctrine\ORM\EntityManagerInterface;
use Mautic\LeadBundle\LeadEvents;
use Mautic\WebhookBundle\Entity\Webhook;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'mautic:webhooks:create',
    description: 'Creates a new Mautic webhook in the database',
)]
class CreateWebhookCommand extends Command
{
    public function __construct(private readonly EntityManagerInterface $em)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->setHelp('This command creates a new webhook in the Mautic database with the specified URL')
            ->addOption(
                'url',
                null,
                InputOption::VALUE_REQUIRED,
                'The webhook URL (e.g., https://example.com/webhook)'
            )
            ->addOption(
                'name',
                null,
                InputOption::VALUE_REQUIRED,
                'The name of the webhook'
            )
            ->addOption(
                'description',
                null,
                InputOption::VALUE_OPTIONAL,
                'Optional description for the webhook'
            )
            ->addOption(
                'secret',
                null,
                InputOption::VALUE_OPTIONAL,
                'Secret key for the webhook (if not provided, a random string will be generated)'
            );
    }

    /**
     * Generates a random string for use as a webhook secret
     */
    private function generateRandomSecret(int $length = 32): string
    {
        $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-_=+';
        $charactersLength = strlen($characters);
        $randomString = '';

        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[random_int(0, $charactersLength - 1)];
        }

        return $randomString;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $url = $input->getOption('url');
        $name = $input->getOption('name');
        $description = $input->getOption('description') ?? '';
        $secret = $input->getOption('secret');

        if (!$url || !$name) {
            $io->error('Both --url and --name options are required.');
            $io->section('Command Usage');
            $io->listing([
                'mautic:webhooks:create --url=<webhook-url> --name=<webhook-name> [--description=<description>] [--secret=<secret-key>]',
                '',
                'Example:',
                'mautic:webhooks:create --url=https://example.com/webhook --name="My Webhook" --description="Description of my webhook" --secret="my-secret-key"',
            ]);
            return Command::FAILURE;
        }

        try {
            return $this->createWebhook($url, $name, $description, $secret, $io);
        } catch (\Exception $e) {
            $io->error(sprintf('Error creating webhook: %s', $e->getMessage()));
            return Command::FAILURE;
        }
    }

    private function createWebhook(string $url, string $name, string $description, ?string $secret, SymfonyStyle $io): int
    {
        // Generate a random secret if none provided
        if (empty($secret)) {
            $secret = $this->generateRandomSecret();
        }

        $io->title('Webhook Creation');
        $io->text([
            sprintf('URL: <comment>%s</comment>', $url),
            sprintf('Name: <comment>%s</comment>', $name),
            sprintf('Description: <comment>%s</comment>', $description),
            sprintf('Secret: <comment>%s</comment>', $secret),
            'Default Events: <comment>Contact Deleted Event, Contact Segment Membership Change Event</comment>',
        ]);

        try {
            // Create a new webhook entity
            $webhook = new Webhook();

            // Set the webhook properties
            $webhook->setName($name);
            $webhook->setWebhookUrl($url);
            $webhook->setSecret($secret);

            if (!empty($description)) {
                $webhook->setDescription($description);
            }

            // Add default events
            $webhook->setTriggers([
                LeadEvents::LEAD_POST_DELETE,  // Contact Deleted Event
                LeadEvents::LEAD_LIST_CHANGE,  // Contact Segment Membership Change Event
            ]);

            // Persist and flush the entity
            $this->em->persist($webhook);
            $this->em->flush();

            $webhookId = $webhook->getId();

            $io->success(sprintf('Successfully created webhook with ID: %s', $webhookId));

            return Command::SUCCESS;
        } catch (\Exception $e) {
            $io->error(sprintf('Error creating webhook: %s', $e->getMessage()));
            return Command::FAILURE;
        }
    }
}
