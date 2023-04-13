
build:
	rm -rf tests/identity
	cp -rp identity tests/
	docker-compose -p django-identity-external -f tests/podman-compose.yml --profile test build

run:
	docker-compose -p django-identity-external -f tests/podman-compose.yml up &
	for i in $$( seq 1 10 ) ; do docker logs django-identity-external_setup_1 2>&1 | grep '^OK /setup' && break ; sleep 5 ; done

restart-app:
	docker-compose -p django-identity-external -f tests/podman-compose.yml exec -T app cp /var/www/django/project/db.sqlite3.initial /var/www/django/project/db.sqlite3

test:
	tests/test.pl http://www:8080/admin bob 'bobovo heslo' djadmin djnimda david 'davidovo heslo'

test-client-container:
	docker-compose -p django-identity-external -f tests/podman-compose.yml --profile test run -T test-client

stop:
	docker-compose -p django-identity-external -f tests/podman-compose.yml down

.PHONY: build run restart-app test test-client-container stop

