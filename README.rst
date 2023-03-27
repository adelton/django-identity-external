
====================================================
	Django identity.external middlewares
====================================================

Set of middlewares to simplify consumption of external identity
information in Web projects set up with Django Web framework.

---------------------------------------------------
identity.external.PersistentRemoteUserMiddlewareVar
---------------------------------------------------

When non-standard (different than ``REMOTE_USER``) environment variable is
used to pass information about externally authenticated user, this
middleware can be used to customize the variable name without writing
Python code.

For example, when consuming the information from some authentication
HTTP proxy, HTTP request header values are passed as ``HTTP_``-prefixed
environment variables. If the authenticated user name is in ``X-Remote-User``
HTTP request header, it is available in ``HTTP_X_REMOTE_USER``
environment variable. Setting variable ``REMOTE_USER_VAR`` to
``HTTP_X_REMOTE_USER``, for example with Apache HTTP Server directive ::

	SetEnv REMOTE_USER_VAR HTTP_X_REMOTE_USER

and enabling ``identity.external.PersistentRemoteUserMiddlewareVar`` in
``MIDDLEWARE`` list after
``django.contrib.auth.middleware.AuthenticationMiddleware`` like ::

	MIDDLEWARE = [
		...
		'django.contrib.auth.middleware.AuthenticationMiddleware',
		'identity.external.PersistentRemoteUserMiddlewareVar',
		...
	]

will run ``django.contrib.auth.middleware.PersistentRemoteUserMiddleware``
with value from environment variable ``HTTP_X_REMOTE_USER``.

------------------------------------------
identity.external.RemoteUserAttrMiddleware
------------------------------------------

When user is externally authenticated, for example via
``django.contrib.auth.middleware.RemoteUserMiddleware`` or
``django.contrib.auth.middleware.PersistentRemoteUserMiddleware``, additional
user attributes can be provided by the external authentication source.

This middleware will update user's email address, first and last name,
and group membership in groups prefixed with ext: with information coming
from environment variables

- ``REMOTE_USER_EMAIL``
- ``REMOTE_USER_FIRSTNAME``
- ``REMOTE_USER_LASTNAME``
- ``REMOTE_USER_GROUP_N``
- ``REMOTE_USER_GROUP_1``, ``REMOTE_USER_GROUP_2``, ...
- ``REMOTE_USER_GROUPS``

where the ``REMOTE_USER`` prefix of these variables can be changed with the
``REMOTE_USER_VAR`` environment variable, just like with
``identity.external.PersistentRemoteUserMiddlewareVar``.

The values are used verbating, as provided by Django. When
``REMOTE_USER_VALUES_ENCODING`` environment variable is set to ``base64url``,
the values are expected to be in this format and decoded to Unicode.

Users that are in external group ``admins`` (and thus get assigned to group
``ext:admins`` in Django) will also get the ``is_staff`` flag set and thus
will be able to log in to the admin application.

The ``ext:`` prefixed groups have to be already created in Django database for
the user membership to be updated in them.

In the ``MIDDLEWARE`` list, this middleware has to be listed after the
authenticating middleware, for example ::

	MIDDLEWARE = [
	    ...
	    'django.contrib.auth.middleware.AuthenticationMiddleware',
	    'django.contrib.auth.middleware.PersistentRemoteUserMiddleware',
	    'identity.external.RemoteUserAttrMiddleware',
	    ...
	]

--------
See also
--------

- *External authentication for Django projects*:
  https://www.adelton.com/django/external-authentication-for-django-projects
  Presentation at EuroPython 2015.
