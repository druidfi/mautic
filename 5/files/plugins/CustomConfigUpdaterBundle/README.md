# CustomConfigUpdaterBundle

Mautic plugin to update webhook URLs in bulk when moving between environments.

## Usage

```bash
# Update URLs
php bin/console mautic:webhooks:replace --source-url="https://old-domain.com" --target-url="https://new-domain.com"

# Preview changes (dry run)
php bin/console mautic:webhooks:replace --source-url="https://old-domain.com" --target-url="https://new-domain.com" --dry-run
```
