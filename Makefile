.PHONY: all build up down restart logs logs-% status health clean rebuild help

all: build

build:
	@echo "Building Docker images..."
	@cd srcs && docker compose build

up:
	@echo "Starting containers..."
	@cd srcs && docker compose up -d

restart:
	@echo "Restarting containers..."
	@cd srcs && docker compose restart

down:
	@echo "Stopping containers..."
	@cd srcs && docker compose down --volumes --remove-orphans

logs:
	@cd srcs && docker compose logs -f

logs-%:
	@cd srcs && docker compose logs -f $*

status:
	@echo "Container Status:"
	@cd srcs && docker compose ps

health:
	@echo "Health Status:"
	@cd srcs && docker compose ps --format "{{.Service}}: {{.State}}"

clean:
	@echo "Cleaning up..."
	@docker container prune -f
	@docker image prune -f

fclean: down
	@echo "Full cleanup - removing images and volumes..."
	@docker system prune -a --volumes -f
	@echo "Cleanup complete!"

rebuild: down clean build up
	@echo "Full rebuild complete!"

help:
	@echo "Inception Makefile — imoulasr"
	@echo ""
	@echo "Targets:"
	@echo "  make build    - Build Docker images"
	@echo "  make up       - Start containers"
	@echo "  make down     - Stop containers"
	@echo "  make restart  - Restart containers"
	@echo "  make logs     - View logs (all)"
	@echo "  make logs-SERVICE - View logs (specific)"
	@echo "  make status   - Show status"
	@echo "  make health   - Show health"
	@echo "  make clean    - Clean up"
	@echo "  make rebuild  - Full reset"
	@echo "  make help     - This help"
