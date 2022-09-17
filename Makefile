
build:
	rm -rf tests/identity
	cp -rp identity tests/
	docker-compose -p django-identity-external -f tests/podman-compose.yml build

run:
	docker-compose -p django-identity-external -f tests/podman-compose.yml up &
	for i in $$( seq 1 10 ) ; do docker logs django-identity-external_setup_1 2>&1 | grep '^OK /setup' && break ; sleep 5 ; done

test:
	tests/test.pl http://www:8080/admin bob 'bobovo heslo' djadmin djnimda david 'davidovo heslo'

stop:
	docker-compose -p django-identity-external -f tests/podman-compose.yml down

.PHONY: build run test

