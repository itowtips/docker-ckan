#!/usr/bin/env bash

/etc/init.d/postgresql start
/etc/init.d/solr start
/etc/init.d/redis-server start
/etc/init.d/nginx start
/etc/init.d/supervisor start
#/etc/init.d/supervisor status

URL="http://127.0.0.1:8080"
while :
do
  RES=$(curl -s $URL);
  if [ -n "$RES" ]; then
    echo "$URL : launch succeeded";
    break
  else
    echo "launch waiting..."
    sleep 1
  fi
done
tail -f /var/log/ckan/ckan-uwsgi.stdout.log
