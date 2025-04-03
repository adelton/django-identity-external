
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null)
endif
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := docker compose
endif

build:
	rm -rf tests/identity
	cp -rp identity tests/
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml --profile test build

run:
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml up &
	for i in $$( seq 1 10 ) ; do docker logs django-identity-external_setup_1 2>&1 | grep '^OK /setup' && break ; sleep 5 ; done

restart-app:
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml exec -T app cp /var/www/django/project/db.sqlite3.initial /var/www/django/project/db.sqlite3

test:
	tests/test.pl http://www:8079/admin bob 'bobovo heslo' djadmin djnimda david 'davidovo heslo'
	$(MAKE) restart-app
	tests/test.pl http://www:8080/admin bob 'bobovo heslo' djadmin djnimda david 'davidovo heslo'

test-client-container:
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml --profile test run -T test-client-saml
	$(MAKE) restart-app
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml --profile test run -T test-client-openidc

stop:
	$(DOCKER_COMPOSE) -p django-identity-external -f $$(pwd)/tests/podman-compose.yml down -v

.PHONY: build run restart-app test test-client-container stop

