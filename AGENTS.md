# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

See `/CLAUDE.md` (monorepo root) for Druid.fi platform standards. This file documents this project's specifics only.

## What this repo is

Builds and publishes the `druidfi/mautic` and `druidfi/mautic-dxp` Docker images — Mautic marketing automation, patched with hotfixes and Druid-specific customizations, in a "plain" variant and a "DXP" variant (branded/wired for Drupal + Mautic integration, see `dxp/` projects in the monorepo root). It does not contain a running application of its own; it's a Dockerfile + build config + a small Mautic plugin, tested via `compose.yaml`.

Images are published to GitHub Container Registry: [ghcr.io/druidfi/mautic](https://github.com/druidfi/druid-mautic-images/pkgs/container/mautic) and [ghcr.io/druidfi/mautic-dxp](https://github.com/druidfi/druid-mautic-images/pkgs/container/mautic-dxp) (`REPO_BASE` in `docker-bake.hcl`).

## Architecture

**Multi-stage Dockerfile (`Dockerfile`)** layers on top of the official `mautic/mautic:<version>-apache` image (injected as the `mautic_upstream` build context, not a static `FROM`):

1. `base` — applies Composer hotfixes (specific `symfony/*` + `twig/twig` packages) and adds the `firemultimedia/mautic-multi-captcha-bundle` plugin. Also installs a few apt packages to fix upstream PHP errors, and copies in the custom Apache vhost, entrypoint script, and supervisord config.
2. `mautic_base_72` — copies the `DruidXPBundle` Mautic plugin from `files/7/plugins/`.
3. `mautic_dxp_72` — layers on DXP branding assets (favicon, logo) from `files/shared/dxp/`.

**Only one Mautic major version is built** (currently 7.2.x). Mautic 5 support was dropped; `files/7/` holds the plugin code, there's no more per-major split to keep in sync.

**`docker-bake.hcl`** defines the actual build matrix: 2 targets (`mautic-72`, `mautic-72-dxp`), each multi-arch (`linux/amd64`, `linux/arm64`), tagged with major, major.minor, and full version. The Mautic upstream version pin lives here (`contexts.mautic_upstream`), not in the Dockerfile — bump it here when updating Mautic core.

**`files/7/plugins/DruidXPBundle`** — a small custom Mautic plugin that adds a "Manage Content" menu item linking back to the paired Drupal site (only rendered when the `DRUPAL_URL` or `DRUPAL_HOSTNAME` env var is set; `DRUPAL_URL` is a full URL and takes precedence, `DRUPAL_HOSTNAME` is linked with `https://`), plus CLI commands (`mautic:webhooks:create`, webhook update command) for managing webhooks from the console.

**`compose.yaml` / `.env`** — a local test harness only (not used in production deploys). Spins up the built image plus a MariaDB 10.11 container, wired for Traefik/Stonehenge routing at `MAUTIC_HOSTNAME`. The commented-out `mautic-cron` / `mautic-worker` services and volume mounts show the intended production shape (separate web/cron/worker roles sharing one image via `DOCKER_MAUTIC_ROLE`), but are disabled for local testing since the Makefile's `up` target only needs `mautic-web` + `mautic-db`.

**`files/entrypoint_mautic_web.sh`** — wraps the upstream Mautic entrypoint: optionally loads test fixtures, auto-installs Mautic if `MAUTIC_AUTO_INSTALL=true` and the DB is empty, runs pending Doctrine migrations on every boot if already installed, then execs into `apache2-foreground` or `php-fpm` depending on `FLAVOUR`.

**`files/supervisord.conf`** — runs Messenger queue consumers (`email`, `hit`, `failed` transports) as supervised background processes inside the same container; worker count and memory/time limits come from `DOCKER_MAUTIC_WORKERS_CONSUME_*`, `DOCKER_MAUTIC_WORKER_MEMORY_LIMIT`, `DOCKER_MAUTIC_WORKER_TIME_LIMIT` env vars.

**`composer.json`** at repo root is a metapackage manifest (not an installable app) — mostly documents the `mautic/core-lib` version constraint this repo targets.

## Common commands

```bash
# Build
docker buildx bake -f docker-bake.hcl --print   # print the build plan / resolved targets
make bake                                        # build both targets locally (linux/arm64, no cache)
make bake-push                                   # multi-arch build + push to GHCR (needs `docker login ghcr.io`; creates/uses a buildx builder)

# Local test environment (uses compose.yaml + .env)
make up                                          # start mautic-web + mautic-db, wait for healthy
make down                                        # tear down
make shell                                       # shell into the mautic-web container as www-data
make install                                     # run mautic:install inside the running container

# Console access
docker compose exec -it -u www-data -w /var/www/html mautic-web php ./bin/console --ansi <command>
```

`.env` controls which built image `compose.yaml` uses (`DOCKER_IMAGE`) and the local hostname (`MAUTIC_HOSTNAME`, routed via Stonehenge/Traefik at `*.docker.so`) — switch `DOCKER_IMAGE` between `-dxp` and non-`-dxp` tags to test a specific variant.

## Working in this repo

- Bake target and Dockerfile stage names use major.minor (`mautic-72`, `mautic_base_72`, `mautic_dxp_72`), not just major — this lets a new minor (e.g. 7.3) or major (8.0) get its own set of targets/stages without colliding with or overwriting the current one during the transition. When bumping the version, add new `-XY`-suffixed targets/stages rather than renaming in place, update `docker-bake.hcl` (`docker-image://` context + `tags` list), and only remove the old ones once the cutover is done.
- When adding a Composer hotfix or plugin, add it to the relevant `RUN composer update|require` block in the `base` stage of the Dockerfile.
- DXP-only branding assets (logo, favicon) live under `files/shared/dxp/`; the non-DXP image build never touches them.

## Checking for new upstream releases

We build on top of `mautic/mautic:<version>-apache`, so a new Mautic release can't be picked up until upstream publishes that image. Upstream images come from [mautic/docker-mautic](https://github.com/mautic/docker-mautic); its "Build and publish a Docker image" workflow is started **manually** (`workflow_dispatch`) on `main`. It does not run automatically on a Mautic release, so the image can lag the [GitHub release](https://github.com/mautic/mautic/releases) by hours or days.

```bash
# Does the upstream image tag exist yet? (200 = yes, 404 = not yet)
curl -s -o /dev/null -w "%{http_code}\n" https://hub.docker.com/v2/repositories/mautic/mautic/tags/7.2.2-apache

# Most recently pushed upstream tags
curl -s "https://hub.docker.com/v2/repositories/mautic/mautic/tags?page_size=15&ordering=last_updated" \
  | jq -r '.results[] | "\(.name)\t\(.last_updated)"'

# Have we published it? (same check for ghcr.io/druidfi/mautic-dxp)
docker manifest inspect ghcr.io/druidfi/mautic:7.2.2 >/dev/null 2>&1 && echo yes || echo no

# When was the Mautic release published?
gh release view 7.2.2 -R mautic/mautic --json publishedAt -q .publishedAt

# Upstream image builds: recent publish runs on main, and anything running right now
gh run list -R mautic/docker-mautic -b main -L 8 \
  --json workflowName,status,conclusion,createdAt,event \
  | jq -r '.[] | "\(.createdAt)\t\(.workflowName)\t\(.status)/\(.conclusion)\t\(.event)"'
gh run list -R mautic/docker-mautic -s in_progress
gh run list -R mautic/docker-mautic -s queued
```

Once the upstream tag exists, bump the `mautic_upstream` context (and `tags`) in `docker-bake.hcl` and run `make bake-push`.
