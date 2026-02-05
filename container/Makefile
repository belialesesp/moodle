.PHONY: help build build-nginx push test clean

IMAGE_NAME ?= nosperifericos/moodle
IMAGE_TAG ?= 5.1
NGINX_IMAGE ?= nosperifericos/moodle-nginx
NGINX_TAG ?= 1.25

help: ## Mostrar ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build imagem PHP-FPM
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile .
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest

build-nginx: ## Build imagem Nginx
	docker build -t $(NGINX_IMAGE):$(NGINX_TAG) -f Dockerfile.nginx .
	docker tag $(NGINX_IMAGE):$(NGINX_TAG) $(NGINX_IMAGE):latest

build-all: build build-nginx ## Build todas as imagens

push: ## Push imagens para registry
	docker push $(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(IMAGE_NAME):latest
	docker push $(NGINX_IMAGE):$(NGINX_TAG)
	docker push $(NGINX_IMAGE):latest

test: ## Testar com docker-compose
	docker-compose up -d
	@echo "Aguardando serviços..."
	@sleep 10
	@echo "Testando..."
	@curl -f http://localhost:8080/health || echo "Health check falhou"
	@docker-compose logs

test-down: ## Parar testes
	docker-compose down

clean: ## Limpar containers e volumes
	docker-compose down -v
	docker system prune -f

logs: ## Ver logs
	docker-compose logs -f

shell-php: ## Shell no container PHP
	docker exec -it moodle-php-fpm bash

shell-nginx: ## Shell no container Nginx
	docker exec -it moodle-nginx sh

lint-dockerfile: ## Lint Dockerfiles
	docker run --rm -i hadolint/hadolint < Dockerfile
	docker run --rm -i hadolint/hadolint < Dockerfile.nginx
