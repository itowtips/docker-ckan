# ckan container for shirasagi

This container is intended to use with shirasagi development.

## BUILD

~~~

docker image build -t shirasagi/ckan . --progress plain

~~~

## RUN

~~~

docker run -d --name ckan --publish=5000:80 --publish=8983:8983 shirasagi/ckan

~~~


## CKAN

### installation

- ubuntu 22.04
- ckan 2.10 ([install-from-package](https://docs.ckan.org/en/2.10/maintaining/installing/install-from-package.html))


### default user

~~~

default / root1234

~~~

~~~

eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJBQVNLX19lQUMwQ3dxV0VjNXZKcW9hQy1zbWt1dExaU0NORWotMzlYZVZBIiwiaWF0IjoxNjg5ODM1ODMyfQ.rWZGXCfSVDN9jISBcJ8qlyVq_bMKKPOokKdUOe65LJ4

~~~

### sys user

~~~

sys / root1234

~~~

~~~

eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIwOGl1SmZmcV9pTjF5TUdtUXBPckFmS0lEcV9KWkl0Rl9VQlBYblhJS3FvIiwiaWF0IjoxNjg5ODM1ODY1fQ.fiOLxcRWc5rgs8JyGwp9xYuTivilL_a40QLbNesaIHY

~~~

### references

- [ckan 2.10.1](https://docs.ckan.org/en/2.10/maintaining/installing/install-from-package.html)
- [datastore](https://docs.ckan.org/en/2.10/maintaining/datastore.html)
- [datapusher](https://github.com/ckan/datapusher)
- [preview plugins](https://docs.ckan.org/en/2.10/maintaining/data-viewer.html)
