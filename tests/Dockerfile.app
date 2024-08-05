FROM registry.fedoraproject.org/fedora:rawhide
ARG DJANGO_VERSION
RUN if test -n "$DJANGO_VERSION" ; then \
		dnf install -y python3-pip && pip install "Django == $DJANGO_VERSION.*" ; \
	else \
		dnf install -y python3-django ; \
	fi \
	&& dnf clean all
RUN mkdir -p /var/www/django
WORKDIR /var/www/django
RUN django-admin startproject project
WORKDIR /var/www/django/project

ADD identity /var/www/django/project/identity

RUN sed -i "/django.contrib.auth.middleware.AuthenticationMiddleware/a 'identity.external.PersistentRemoteUserMiddlewareVar', 'identity.external.RemoteUserAttrMiddleware'," project/settings.py
RUN sed -i "/^MIDDLEWARE =/iAUTHENTICATION_BACKENDS = [ 'django.contrib.auth.backends.RemoteUserBackend', 'django.contrib.auth.backends.ModelBackend', ]" project/settings.py
RUN echo 'ALLOWED_HOSTS = [ "*" ]' >> project/settings.py
RUN echo 'CSRF_TRUSTED_ORIGINS = [ "http://www:8079", "http://www:8080" ]' >> project/settings.py

RUN python3 manage.py migrate
RUN echo "from django.contrib.auth.models import User; User.objects.create_superuser('djadmin', 'admin@example.test', 'djnimda');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:admins');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:group-2');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:group-3');" | python3 manage.py shell
RUN cp -p /var/www/django/project/db.sqlite3 /var/www/django/project/db.sqlite3.initial
ENV REMOTE_USER_VAR HTTP_X_REMOTE_USER
ENV REMOTE_USER_VALUES_ENCODING base64url
ENTRYPOINT [ "python3", "manage.py", "runserver", "app:8081" ]
