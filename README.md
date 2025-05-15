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
docker buildx bake --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'
```

Build and push images:

```console
docker buildx bake build --pull --no-cache --push
```
