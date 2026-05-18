.PHONY: up down logs build migrate test lint format clean

# Démarrer tous les services (dev)
up:
	docker compose up -d

# Démarrer avec PgAdmin
up-dev:
	docker compose --profile dev up -d

# Arrêter les services
down:
	docker compose down

# Arrêter et supprimer les volumes
down-v:
	docker compose down -v

# Voir les logs en temps réel
logs:
	docker compose logs -f

logs-backend:
	docker compose logs -f backend

# Builder les images
build:
	docker compose build --no-cache

# Appliquer les migrations Alembic
migrate:
	docker compose exec backend alembic upgrade head

# Créer une migration
migration:
	docker compose exec backend alembic revision --autogenerate -m "$(name)"

# Lancer les tests backend
test:
	docker compose exec backend pytest tests/ -v --cov=app --cov-report=term-missing

# Linter le code backend
lint:
	docker compose exec backend ruff check app/ tests/

# Formater le code
format:
	docker compose exec backend ruff format app/ tests/

# Nettoyer les conteneurs et images inutilisées
clean:
	docker system prune -f

# Production
up-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

down-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down

# Accès shell
shell-backend:
	docker compose exec backend bash

shell-db:
	docker compose exec db psql -U ouicooly -d ouicooly_db
