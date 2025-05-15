# Druid Mautic Docker images

## Variants

- `druidfi/mautic` - Default image with no DXP brand
- `druidfi/mautic:dxp` - DXP branded image

## Build

Print the build plan:

```console
docker buildx bake --print
```

Build images locally:

```console
docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'
```

Build and push images:

```console
docker buildx bake -f docker-bake.hcl build --pull --no-cache --push
```

## Testing

```console
docker compose up --wait
```

Open https://mautid-dxp.docker.so/
