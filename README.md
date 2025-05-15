# Druid Mautic Docker images

## Variants

- `druidfi/mautic` - Default image with no DXP brand
- `druidfi/mautic-dxp` - DXP branded image

## Tagging

- `:5` - Latest stable release
- `:5.2` - Latest stable minor release
- `:5.2.5` - Stable patch release

## Build

Print the build plan:

```console
docker buildx bake --print
```

Build images locally:

```console
docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'
```

Build and push images (needs Docker Hub credentials):

```console
docker buildx bake -f docker-bake.hcl --pull --no-cache --push
```

## Testing

```console
docker compose up --wait
docker compose exec -it -u www-data -w /var/www/html mautic-app php ./bin/console --ansi \
    mautic:install --admin_firstname=Admin --admin_lastname=Administer \
    --admin_email=admin@yourdomain.com \
    --admin_username=admin \
    --admin_password=adminpassu \
    --db_host=mautic-db --db_port=3306 \
    --db_user=mautic --db_password=mautic \
    --db_name=mautic \
    http://mautic-dxp.docker.so
```

Open https://mautic-dxp.docker.so/
