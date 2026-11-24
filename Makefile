.DEFAULT_GOAL := help
.PHONY: help up down logs ps test lint check user
help:
	@echo "make up      Construir e iniciar o app local"
	@echo "make down    Parar o app e preservar os dados"
	@echo "make ps      Ver estado dos contêineres"
	@echo "make logs    Acompanhar logs da aplicação"
	@echo "make test    Executar a suíte Rails no Docker"
	@echo "make lint    Executar o RuboCop no Docker"
	@echo "make check   Executar testes e lint"
	@echo "make user    Criar uma conta local"
up:
	docker compose up --build -d
down:
	docker compose down
ps:
	docker compose ps
logs:
	docker compose logs -f web
test:
	docker compose run --build --rm --no-deps -e RAILS_ENV=test web sh -ec "bin/rails db:prepare && bin/rails test"
lint:
	docker compose run --build --rm --no-deps web bin/rubocop
check: test lint
user:
	docker compose exec web bin/rails fittracker:user
