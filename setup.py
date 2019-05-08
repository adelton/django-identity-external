import os
from setuptools import find_packages, setup

with open(os.path.join(os.path.dirname(__file__), 'README.rst')) as readme:
	README = readme.read()

# allow setup.py to be run from any path
os.chdir(os.path.normpath(os.path.join(os.path.abspath(__file__), os.pardir)))

setup(
	name = 'django-identity-external',
	version = '0.5.3',
	packages = find_packages(),
	include_package_data = True,
	license = 'Apache 2.0 License',
	description = 'Django middleware for handling of external identities.',
	long_description = README,
	long_description_content_type = 'text/x-rst',
	url = 'https://github.com/adelton/django-identity-external',
	author = 'Jan Pazdziora',
	author_email = 'jan.pazdziora@django.adelton.com',
	install_requires = [
		'django>=1.9,<2.0',
	],
	classifiers = [
		'Environment :: Web Environment',
		'Framework :: Django',
		# New PersistentRemoteUserMiddleware in Django 1.9
		'Framework :: Django :: 1.9',
		'Intended Audience :: Developers',
		'License :: OSI Approved :: Apache Software License',
		'Operating System :: OS Independent',
		'Programming Language :: Python',
		'Programming Language :: Python :: 2.7',
		'Programming Language :: Python :: 3',
		'Programming Language :: Python :: 3.4',
		'Programming Language :: Python :: 3.5',
		'Topic :: Internet :: WWW/HTTP',
		'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
	],
)
