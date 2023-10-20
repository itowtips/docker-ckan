FROM ubuntu:22.04
LABEL maintainer="ITO Yu <ito@web-tips.co.jp>"

WORKDIR /usr/local/src

RUN sed -i '$a * soft nofile 1048576\n* hard nofile 1048576\n' /etc/security/limits.conf
RUN apt update
RUN apt install -y locales
RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ Asia/Tokyo

# ckan 2.10.1     https://docs.ckan.org/en/2.10/maintaining/installing/install-from-package.html
# datastore       https://docs.ckan.org/en/2.10/maintaining/datastore.html
# datapusher      https://github.com/ckan/datapusher
# preview plugins https://docs.ckan.org/en/2.10/maintaining/data-viewer.html

RUN apt install -y curl wget sudo lsof git vim
RUN apt install -y libpq5 redis-server nginx supervisor
RUN apt install -y python3 python3-distutils libmagic-dev
RUN apt install -y openjdk-8-jdk
RUN apt install -y python3-venv python3-dev build-essential

# 1. Install the CKAN package
RUN wget https://packaging.ckan.org/python-ckan_2.10-jammy_amd64.deb
RUN dpkg -i python-ckan_2.10-jammy_amd64.deb

RUN . /usr/lib/ckan/default/bin/activate &&\
  pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt &&\
  pip install -r /usr/lib/ckan/default/src/ckan/dev-requirements.txt &&\
  pip install ckanext-pdfview

RUN . /usr/lib/ckan/datapusher/bin/activate &&\
  pip install -r /usr/lib/ckan/datapusher/src/datapusher/requirements.txt &&\
  pip install -r /usr/lib/ckan/datapusher/src/datapusher/requirements-dev.txt

# patch at datapusher
RUN rm -rf /usr/lib/ckan/datapusher/lib/python3.10/site-packages/messytables/core.py
COPY assets/patch/messytables/core.py /usr/lib/ckan/datapusher/lib/python3.10/site-packages/messytables/core.py

RUN rm -rf /usr/lib/ckan/datapusher/lib/python3.10/site-packages/html5lib/_trie/_base.py
COPY assets/patch/html5lib/_trie/_base.py /usr/lib/ckan/datapusher/lib/python3.10/site-packages/html5lib/_trie/_base.py

# 2. Install and configure PostgreSQL
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y postgresql
RUN sed -i "s/^local   all             postgres                                peer$/local   all             postgres                                trust/" /etc/postgresql/14/main/pg_hba.conf
RUN sed -i "s/^local   all             all                                     peer$/local   all             all                                     md5/" /etc/postgresql/14/main/pg_hba.conf
RUN sed -i "s/^local   replication     all                                     peer$/local   replication     all                                     md5/" /etc/postgresql/14/main/pg_hba.conf
#RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf
RUN /etc/init.d/postgresql start &&\
  /usr/bin/psql -U postgres --command "CREATE USER ckan_default WITH SUPERUSER PASSWORD 'pass';" &&\
  /usr/bin/createdb -U postgres -O ckan_default ckan_default -E utf-8 &&\
  /usr/bin/psql -U postgres --command "CREATE USER datastore_default PASSWORD 'pass';" &&\
  /usr/bin/createdb -U postgres -O ckan_default datastore_default -E utf-8

# 3. Install and configure Solr
RUN wget -O solr-8.11.2.tgz https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.2/solr-8.11.2.tgz?action=download
RUN tar xzf solr-8.11.2.tgz solr-8.11.2/bin/install_solr_service.sh --strip-components=2
RUN ./install_solr_service.sh solr-8.11.2.tgz &&\
  su solr -c "/opt/solr/bin/solr create -c ckan"
RUN su solr -c "wget -O /var/solr/data/ckan/conf/managed-schema https://raw.githubusercontent.com/ckan/ckan/dev-v2.10/ckan/config/solr/schema.xml"

# 4. Set up a writable directory
RUN mkdir -p /var/lib/ckan/default
RUN chown www-data /var/lib/ckan/default
RUN chmod u+rwx /var/lib/ckan/default

# 5. Update the configuration and initialize the database
RUN rm -rf /etc/ckan/default/ckan.ini
COPY assets/ckan.ini /etc/ckan/default/ckan.ini

ARG site_url="http://localhost:8080"
RUN sed -i "s;^ckan\.site_url = http://127.0.0.1:5000$;ckan.site_url = $site_url;" /etc/ckan/default/ckan.ini

COPY assets/ckan_default.dump .
RUN /etc/init.d/postgresql start &&\
  psql -U postgres ckan_default < ckan_default.dump

RUN /etc/init.d/postgresql start &&\
  /etc/init.d/solr start &&\
  /etc/init.d/redis-server start &&\
  /etc/init.d/supervisor start &&\
  /etc/init.d/nginx start &&\
  ckan -c /etc/ckan/default/ckan.ini datastore set-permissions | sudo -u postgres psql --set ON_ERROR_STOP=1

# sudo ckan db init &&\
# ckan -c /etc/ckan/default/ckan.ini sysadmin add sys email=sys@example.jp name=sys

# nginx      80
# ckan       8080
# datapusher 8800
# solr       8983
EXPOSE 80
EXPOSE 8080
EXPOSE 8800
EXPOSE 8983

COPY assets/launch.sh .
RUN chmod +x launch.sh
CMD ./launch.sh

# docker image build -t shirasagi/ckan . --progress plain
# docker run -d --name ckan --publish=8080:80 --publish=8800:8800 --publish=8983:8983 shirasagi/ckan

# access to
# http://localhost:8080/
# http://localhost:8080/user/login/
# http://localhost:8080/ckan-admin/

# CKAN USERS
# default / root1234
# eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJBQVNLX19lQUMwQ3dxV0VjNXZKcW9hQy1zbWt1dExaU0NORWotMzlYZVZBIiwiaWF0IjoxNjg5ODM1ODMyfQ.rWZGXCfSVDN9jISBcJ8qlyVq_bMKKPOokKdUOe65LJ4
#
# sys / root1234
# eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIwOGl1SmZmcV9pTjF5TUdtUXBPckFmS0lEcV9KWkl0Rl9VQlBYblhJS3FvIiwiaWF0IjoxNjg5ODM1ODY1fQ.fiOLxcRWc5rgs8JyGwp9xYuTivilL_a40QLbNesaIHY
