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


### admin user

~~~

sys / root1234

~~~

### api key

~~~

eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIwWVltSlMzNUdyVFFoRmVpRkdqR3lFV0VUQ0tyS0ZKM3NFcFZXd1VmamtnIiwiaWF0IjoxNjg5MTQyOTY3fQ.RH4fAt8i5IJomMY0K5kbBhMQ99mdTT34J8D6Uk0_iYY

~~~

