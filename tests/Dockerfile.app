FROM registry.fedoraproject.org/fedora
RUN dnf install -y python3-django && dnf clean all
RUN mkdir -p /var/www/django
WORKDIR /var/www/django
RUN django-admin startproject project
WORKDIR /var/www/django/project

ADD identity /var/www/django/project/identity

RUN sed -i "/django.contrib.auth.middleware.AuthenticationMiddleware/a 'identity.external.PersistentRemoteUserMiddlewareVar', 'identity.external.RemoteUserAttrMiddleware'," project/settings.py
RUN sed -i "/^MIDDLEWARE =/iAUTHENTICATION_BACKENDS = [ 'django.contrib.auth.backends.RemoteUserBackend', 'django.contrib.auth.backends.ModelBackend', ]" project/settings.py
RUN echo 'ALLOWED_HOSTS = [ "*" ]' >> project/settings.py

RUN python3 manage.py migrate
RUN echo "from django.contrib.auth.models import User; User.objects.create_superuser('djadmin', 'admin@example.test', 'djnimda');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:admins');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:group-2');" | python3 manage.py shell
RUN echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:group-3');" | python3 manage.py shell
ENV REMOTE_USER_VAR HTTP_X_REMOTE_USER
ENV REMOTE_USER_VALUES_ENCODING base64url
ENTRYPOINT [ "python3", "manage.py", "runserver", "app:8081" ]
