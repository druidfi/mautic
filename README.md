# Mautic v5 - Druid Variant

Setup

```console
docker compose up --build --wait
docker compose exec mautic bin/console mautic:install https://mautic.docker.so
```

Open shell into the container:

```console
docker compose exec mautic sh
```

## Deployment

```console
bin/console cache:clear
bin/console mautic:update:apply --finish
bin/console doctrine:migration:migrate --no-interaction
bin/console doctrine:schema:update --no-interaction --force
bin/console cache:clear
```
