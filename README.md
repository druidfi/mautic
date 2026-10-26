# Druid Mautic Docker images

## Variants

- [ghcr.io/druidfi/mautic](https://github.com/druidfi/druid-mautic-images/pkgs/container/mautic) - Default image with no DXP brand
- [ghcr.io/druidfi/mautic-dxp](https://github.com/druidfi/druid-mautic-images/pkgs/container/mautic-dxp) - DXP branded image

## Tagging

- `:7` - Latest stable release
- `:7.2` - Latest stable minor release
- `:7.2.2` - Stable patch release

## Build

Print the build plan:

```console
docker buildx bake -f docker-bake.hcl --print
```

Build images locally:

```console
docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'
```

Build and push images (needs `docker login ghcr.io` with a token that has `write:packages`):

```console
docker buildx inspect mautic-builder >/dev/null 2>&1 || docker buildx create --name mautic-builder --platform linux/amd64,linux/arm64
docker buildx use mautic-builder
docker buildx bake -f docker-bake.hcl --pull --no-cache --push
```

## Testing

```console
docker compose up --wait
docker compose exec -it -u www-data -w /var/www/html mautic-web php ./bin/console --ansi \
    mautic:install --force --admin_firstname=Admin --admin_lastname=Administer \
    --admin_email=admin@yourdomain.com \
    --admin_username=admin \
    --admin_password=adminpassu \
    https://mautic-dxp.docker.so
```

Open https://mautic-dxp.docker.so/

Open shell into Mautic container:

```console
docker compose exec -it -u www-data -w /var/www/html mautic-web /bin/bash
```

Run console:

```console
php bin/console --ansi about
```
