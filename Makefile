MAUTIC_WEB_CONTAINER := mautic-web

##
## Build
##

.PHONY: bake-print
bake-print: ## Print the build plan
	docker buildx bake -f docker-bake.hcl --print

.PHONY: bake
bake: ## Build images locally (linux/arm64)
	docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set '*.platform=linux/arm64'

.PHONY: bake-push
bake-push: ## Build and push images to Docker Hub (needs credentials)
	docker buildx inspect mautic-builder >/dev/null 2>&1 || docker buildx create --name mautic-builder --platform linux/amd64,linux/arm64
	docker buildx use mautic-builder
	docker buildx bake -f docker-bake.hcl --pull --no-cache --push
	docker buildx rm mautic-builder

##
## Testing
##

.PHONY: up
up: ## Start containers and wait for healthy
	docker compose up --wait

.PHONY: down
down: ## Stop and remove containers
	docker compose down

.PHONY: shell
shell: ## Open shell into Mautic web container
	docker compose exec -it -u www-data -w /var/www/html $(MAUTIC_WEB_CONTAINER) /bin/bash

.PHONY: install
install: ## Run mautic:install in the web container
	docker compose exec -it -u www-data -w /var/www/html $(MAUTIC_WEB_CONTAINER) php ./bin/console --ansi \
		mautic:install --force \
		--admin_firstname=Admin \
		--admin_lastname=Administer \
		--admin_email=admin@yourdomain.com \
		--admin_username=admin \
		--admin_password=adminpassu \
		https://mautic-dxp.docker.so

##
## Help
##

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
