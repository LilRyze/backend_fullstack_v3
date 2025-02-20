include .env

docker_php = frozeneon-php
docker_mysql = frozeneon-mysql

MYSQL_DUMPS_DIR=./db_dump

help:
	@echo ""
	@echo "usage: make COMMAND"
	@echo ""
	@echo "Commands:"
	@echo "  clean               Clean directories for reset"
	@echo "  composer-up         Update PHP dependencies with composer"
	@echo "  init                Cleanup data files and reinit project"
	@echo "  docker-start        Create and start containers"
	@echo "  docker-stop         Stop all services"
	@echo "  gen-certs           Generate SSL certificates"
	@echo "  logs                Follow log output"
	@echo "  mysql-init          Init database"

init:
	@make clean
	@make docker-start
	@echo "[$$(date '+%Y-%m-%d %H:%M:%S')] Wait 25 seconds to initialize MySQL"
	@sleep 25
	@make mysql-init
	@make composer-up

clean:
	-@docker rm $$(docker stop frozeneon-nginx)
	-@docker rm $$(docker stop frozeneon-php)
	-@docker rm $$(docker stop frozeneon-phpmyadmin)
	-@docker rm $$(docker stop frozeneon-mysql)
	-@rm -Rf data/db/*

composer-up:
	@docker exec -u root -i -w /var/www/html/application $(docker_php) composer install --prefer-source --no-interaction

docker-start:
	docker-compose up -d

docker-stop:
	@docker-compose --env-file .env stop

gen-certs:
	@docker run --rm -v $(shell pwd)/etc/ssl:/certificates -e "SERVER=$(NGINX_HOST)" jacoelho/generate-certificate

logs:
	@docker-compose logs -f

mysql-init:
	@docker exec -i $(docker_mysql) mysql -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" test_task < $(MYSQL_DUMPS_DIR)/init_db.sql

.PHONY: clean init help