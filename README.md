# Mautic v5 - Druid Variant

## Create empty Mautic instance:

```console
make fresh
```

Open https://mautic.docker.so and use `mautic@druid.fi:mautic` as credentials.

## Create Mautic instance with demo data

```console
docker compose up --build --wait
docker compose exec mautic bin/console mautic:install https://mautic.docker.so
docker compose exec mautic bin/console doctrine:fixtures:load --no-interaction
```

Open https://mautic.docker.so and use `admin@yoursite.com:mautic` as credentials.

## Open shell into the container:

```console
make shell
```

## Deployment

```console
bin/console cache:clear
bin/console mautic:update:apply --finish
bin/console doctrine:migration:migrate --no-interaction
bin/console doctrine:schema:update --no-interaction --force
bin/console cache:clear
```

## Install options

```
--db_driver=DB_DRIVER                Database driver.
--db_host=DB_HOST                    Database host.
--db_port=DB_PORT                    Database port.
--db_name=DB_NAME                    Database name.
--db_user=DB_USER                    Database user.
--db_password=DB_PASSWORD            Database password.
--db_table_prefix=DB_TABLE_PREFIX    Database tables prefix.
--db_backup_tables=DB_BACKUP_TABLES  Backup database tables if they exist; otherwise drop them. (true|false)
--db_backup_prefix=DB_BACKUP_PREFIX  Database backup tables prefix.
--admin_firstname=ADMIN_FIRSTNAME    Admin first name.
--admin_lastname=ADMIN_LASTNAME      Admin last name.
--admin_username=ADMIN_USERNAME      Admin username.
--admin_email=ADMIN_EMAIL            Admin email.
--admin_password=ADMIN_PASSWORD      Admin user.
```
