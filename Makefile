PHONY :=

ANSIBLE_INVENTORY_PATH ?= ansible/inventory
ANSIBLE_PROVISION ?= ansible/provision.yml

DB_NAME ?= mautic-demo
DB_USER ?= mautic-demo
DB_PASS ?= mautic-demo

PHONY += fresh
fresh:
	docker compose down -v --remove-orphans
	docker compose up --build --wait
	docker compose exec mautic bin/console mautic:install https://mautic.docker.so

PHONY += down
down:
	docker compose down -v --remove-orphans

PHONY += open-db-gui
open-db-gui: ## Open database with GUI tool
	@open mysql://$(DB_USER):$(DB_PASS)@$(shell docker compose port db 3306 | grep -v ::)/$(DB_NAME)

PHONY += shell
shell:
	docker compose exec mautic sh

PHONY += build
build:
	docker buildx bake -f docker-bake.hcl --pull --progress plain --no-cache --load --set "*.platform=linux/arm64"

PHONY += release
release:
	docker buildx bake -f docker-bake.hcl --pull --no-cache --push

.PHONY: $(PHONY)
