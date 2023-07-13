FROM ubuntu:22.04
LABEL maintainer="ITO Yu <ito@web-tips.co.jp>"

WORKDIR /usr/local/src

RUN apt-get update
RUN apt-get install -y locales

RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ Asia/Tokyo

# https://docs.ckan.org/en/2.10/maintaining/installing/install-from-package.html

RUN apt install -y wget vim lsof sudo git
RUN apt install -y libpq5 redis-server nginx supervisor
RUN apt install -y python3 python3-distutils libmagic-dev
RUN apt install -y openjdk-8-jdk

# 1. Install the CKAN package
RUN wget https://packaging.ckan.org/python-ckan_2.10-jammy_amd64.deb
RUN dpkg -i python-ckan_2.10-jammy_amd64.deb

# 2. Install and configure PostgreSQL
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y postgresql
RUN sed -i "s/^local   all             postgres                                peer$/local   all             postgres                                trust/" /etc/postgresql/14/main/pg_hba.conf
RUN sed -i "s/^local   all             all                                     peer$/local   all             all                                     md5/" /etc/postgresql/14/main/pg_hba.conf
RUN sed -i "s/^local   replication     all                                     peer$/local   replication     all                                     md5/" /etc/postgresql/14/main/pg_hba.conf
#RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf
RUN /etc/init.d/postgresql start &&\
  /usr/bin/psql -U postgres --command "CREATE USER ckan_default WITH SUPERUSER PASSWORD 'pass';" &&\
  /usr/bin/createdb -U postgres -O ckan_default ckan_default -E utf-8

# 3. Install and configure Solr
RUN wget -O solr-8.11.2.tgz https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.2/solr-8.11.2.tgz?action=download
RUN tar xzf solr-8.11.2.tgz solr-8.11.2/bin/install_solr_service.sh --strip-components=2
RUN ./install_solr_service.sh solr-8.11.2.tgz &&\
  su solr -c "/opt/solr/bin/solr create -c ckan"
RUN su solr -c "wget -O /var/solr/data/ckan/conf/managed-schema https://raw.githubusercontent.com/ckan/ckan/dev-v2.10/ckan/config/solr/schema.xml"
EXPOSE 8983

# 4. Set up a writable directory
RUN mkdir -p /var/lib/ckan/default
RUN chown www-data /var/lib/ckan/default
RUN chmod u+rwx /var/lib/ckan/default

# 5. Update the configuration and initialize the database
RUN rm -rf /etc/ckan/default/ckan.ini
COPY assets/ckan.ini /etc/ckan/default/ckan.ini

ARG site_url="http://localhost:5000"
RUN sed -i "s;^ckan\.site_url = http://127.0.0.1:5000$;ckan.site_url = $site_url;" /etc/ckan/default/ckan.ini

RUN . /usr/lib/ckan/default/bin/activate &&\
  pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt &&\
  pip install -r /usr/lib/ckan/default/src/ckan/dev-requirements.txt

COPY assets/ckan_default.dump .
RUN /etc/init.d/postgresql start &&\
  psql -U postgres ckan_default < ckan_default.dump
EXPOSE 80

# . /usr/lib/ckan/default/bin/activate
# cd /usr/lib/ckan/default/src/ckan
# ckan -c /etc/ckan/default/ckan.ini sysadmin add sys email=sys@example.jp name=sys
# root1234

# APIKEY
# eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIwWVltSlMzNUdyVFFoRmVpRkdqR3lFV0VUQ0tyS0ZKM3NFcFZXd1VmamtnIiwiaWF0IjoxNjg5MTQyOTY3fQ.RH4fAt8i5IJomMY0K5kbBhMQ99mdTT34J8D6Uk0_iYY

# docker image build -t shirasagi/ckan . --progress plain
# docker run --name test-container1 --publish=5000:80 --publish=8983:8983 -it shirasagi/ckan /bin/bash

#service postgresql start
#service solr start
#service redis-server start
#service supervisor start
#service nginx start
