include ./srcs/.env

all: build up

volumes:
	sudo mkdir -p $(VOLUME_MARIADB)
	sudo mkdir -p $(VOLUME_WORDPRESS)

build: volumes
	docker compose -f $(DOCKER_COMPOSE_FILE) build --no-cache

up:
	docker compose -f $(DOCKER_COMPOSE_FILE) up


down:
	docker compose -f $(DOCKER_COMPOSE_FILE) down

clean:
	docker compose -f $(DOCKER_COMPOSE_FILE) down --volumes --remove-orphans

fclean:
	docker compose -f $(DOCKER_COMPOSE_FILE) down --volumes --remove-orphans --rmi all
	sudo rm -rf $(VOLUME_MARIADB)
	sudo rm -rf $(VOLUME_WORDPRESS)

re: fclean all

logs:
	docker compose -f $(DOCKER_COMPOSE_FILE) logs -f

stats:
	docker stats

.PHONY: all volumes build up down clean fclean re logs stats
