# Druid Mautic Docker images

## Variants

- [druidfi/mautic](https://hub.docker.com/r/druidfi/mautic/tags) - Default image with no DXP brand
- [druidfi/mautic-dxp](https://hub.docker.com/r/druidfi/mautic-dxp/tags) - DXP branded image

## Tagging

- `:5` - Latest stable release
- `:5.2` - Latest stable minor release
- `:5.2.9` - Stable patch release

## Build

Print the build plan:

```console
docker buildx bake -f docker-bake.hcl --print
```

Build images locally:

```console
docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'
```

Build and push images (needs Docker Hub credentials):

```console
docker buildx create --use --platform linux/amd64,linux/arm64
docker buildx bake -f docker-bake.hcl --pull --no-cache --push
```

## Testing

```console
docker compose up --wait
docker compose exec -it -u www-data -w /var/www/html mautic-app php ./bin/console --ansi \
    mautic:install --force --admin_firstname=Admin --admin_lastname=Administer \
    --admin_email=admin@yourdomain.com \
    --admin_username=admin \
    --admin_password=adminpassu \
    http://mautic-dxp.docker.so
```

Open https://mautic-dxp.docker.so/

Open shell into Mautic container:

```console
docker compose exec -it -u www-data -w /var/www/html mautic-app /bin/bash
```

Run console:

```console
php bin/console --ansi about
```
