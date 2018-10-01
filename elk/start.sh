#!/bin/bash
#
# /usr/local/bin/start.sh
# Start Elasticsearch, Logstash and Kibana services
#
# spujadas 2015-10-09; added initial pidfile removal and graceful termination

# WARNING - This script assumes that the ELK services are not running, and is
#   only expected to be run once, when the container is started.
#   Do not attempt to run this script if the ELK services are running (or be
#   prepared to reap zombie processes).


## handle termination gracefully

_term() {
  echo "Terminating ELK"
  service elasticsearch stop
  service logstash stop
  service kibana stop
  exit 0
}

trap _term SIGTERM

## remove pidfiles in case previous graceful termination failed
# NOTE - This is the reason for the WARNING at the top - it's a bit hackish,
#   but if it's good enough for Fedora (https://goo.gl/88eyXJ), it's good
#   enough for me :)

rm -f /var/run/elasticsearch/elasticsearch.pid /var/run/logstash.pid \
  /var/run/kibana5.pid

####################################
### APACHE REVERSE PROXY SECTION ###
####################################
# The reverse proxy will require .htpasswd authentication on port 80/443 for client usage.
# Log-sending applications communicate with elastic on port 9200 (via logstash ports 5000 and 5044) which does not
# require authentication. This is fine, as long as ports 5000, 5044 and 9200 are not exposed outside of the Docker network
# OR if access to those ports is regulated by iptables, thereby only allowing trusted log-sending services.

#Create htpassword file
htpasswd -c -db /opt/.htpasswd elastic $ELASTIC_PASSWORD

##Make apache owner of the htpasswd file
chown www-data:www-data /opt/.htpasswd

### apache2 modules enable and server restart 
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_ajp
a2enmod rewrite
a2enmod deflate
a2enmod headers
a2enmod proxy_balancer
a2enmod proxy_connect
a2enmod proxy_html

service apache2 restart

####################################

## initialise list of log files to stream in console (initially empty)
OUTPUT_LOGFILES=""

### crond

service cron start

### Elasticsearch

if [ -z "$ELASTICSEARCH_START" ]; then
  ELASTICSEARCH_START=1
fi
if [ "$ELASTICSEARCH_START" -ne "1" ]; then
  echo "ELASTICSEARCH_START is set to something different from 1, not starting..."
else
  # override ES_HEAP_SIZE variable if set
  if [ ! -z "$ES_HEAP_SIZE" ]; then
    awk -v LINE="ES_HEAP_SIZE=\"$ES_HEAP_SIZE\"" '{ sub(/^#?ES_HEAP_SIZE=.*/, LINE); print; }' /etc/default/elasticsearch \
        > /etc/default/elasticsearch.new && mv /etc/default/elasticsearch.new /etc/default/elasticsearch
  fi
  # override ES_JAVA_OPTS variable if set
  if [ ! -z "$ES_JAVA_OPTS" ]; then
    awk -v LINE="ES_JAVA_OPTS=\"$ES_JAVA_OPTS\"" '{ sub(/^#?ES_JAVA_OPTS=.*/, LINE); print; }' /etc/default/elasticsearch \
        > /etc/default/elasticsearch.new && mv /etc/default/elasticsearch.new /etc/default/elasticsearch
  fi

  service elasticsearch start

  # wait for Elasticsearch to start up before either starting Kibana (if enabled)
  # or attempting to stream its log file
  # - https://github.com/elasticsearch/kibana/issues/3077

  # set number of retries (default: 30, override using ES_CONNECT_RETRY env var)
  re_is_numeric='^[0-9]+$'
  if ! [[ $ES_CONNECT_RETRY =~ $re_is_numeric ]] ; then
     ES_CONNECT_RETRY=60
  fi

  counter=0
  while [ ! "$(curl localhost:9200 2> /dev/null)" -a $counter -lt $ES_CONNECT_RETRY  ]; do
    sleep 1
    ((counter++))
    echo "waiting for Elasticsearch to be up ($counter/$ES_CONNECT_RETRY)"
  done
  if [ ! "$(curl localhost:9200 2> /dev/null)" ]; then
    echo "Couln't start Elasticsearch. Exiting."
    echo "Elasticsearch log follows below."
    cat /var/log/elasticsearch/elasticsearch.log
    exit 1
  fi

  # wait for cluster to respond before getting its name
  counter=0
  while [ -z "$CLUSTER_NAME" -a $counter -lt 30 ]; do
    sleep 1
    ((counter++))
    CLUSTER_NAME=$(curl localhost:9200/_cat/health?h=cluster 2> /dev/null | tr -d '[:space:]')
    echo "Waiting for Elasticsearch cluster to respond ($counter/30)"
  done
  if [ -z "$CLUSTER_NAME" ]; then
    echo "Couln't get name of cluster. Exiting."
    echo "Elasticsearch log follows below."
    cat /var/log/elasticsearch/elasticsearch.log
    exit 1
  fi
  OUTPUT_LOGFILES+="/var/log/elasticsearch/${CLUSTER_NAME}.log "
fi


### Logstash

if [ -z "$LOGSTASH_START" ]; then
  LOGSTASH_START=1
fi
if [ "$LOGSTASH_START" -ne "1" ]; then
  echo "LOGSTASH_START is set to something different from 1, not starting..."
else
  # override LS_HEAP_SIZE variable if set
  if [ ! -z "$LS_HEAP_SIZE" ]; then
    awk -v LINE="LS_HEAP_SIZE=\"$LS_HEAP_SIZE\"" '{ sub(/^LS_HEAP_SIZE=.*/, LINE); print; }' /etc/init.d/logstash \
        > /etc/init.d/logstash.new && mv /etc/init.d/logstash.new /etc/init.d/logstash && chmod +x /etc/init.d/logstash
  fi

  # override LS_OPTS variable if set
  if [ ! -z "$LS_OPTS" ]; then
    awk -v LINE="LS_OPTS=\"$LS_OPTS\"" '{ sub(/^LS_OPTS=.*/, LINE); print; }' /etc/init.d/logstash \
        > /etc/init.d/logstash.new && mv /etc/init.d/logstash.new /etc/init.d/logstash && chmod +x /etc/init.d/logstash
  fi

  service logstash start
  OUTPUT_LOGFILES+="/var/log/logstash/logstash-plain.log "
fi


### Kibana

if [ -z "$KIBANA_START" ]; then
  KIBANA_START=1
fi
if [ "$KIBANA_START" -ne "1" ]; then
  echo "KIBANA_START is set to something different from 1, not starting..."
else
  service kibana start
  OUTPUT_LOGFILES+="/var/log/kibana/kibana5.log "
fi

# Exit if nothing has been started
if [ "$ELASTICSEARCH_START" -ne "1" ] && [ "$LOGSTASH_START" -ne "1" ] \
  && [ "$KIBANA_START" -ne "1" ]; then
  >&2 echo "No services started. Exiting."
  exit 1
fi


cd /tmp
elasticdump --input=kibana-exported.json --output=http://localhost:9200/.kibana --type=data

# import index templates in elastic
echo "importing index templates"
curl -XPUT 'http://localhost:9200/_template/core' -d@/tmp/template.core.json
curl -XPUT 'http://localhost:9200/_template/aux' -d@/tmp/template.aux.json


# create dummy indexes (to avoid issues when ceating aliases)
echo "create indexes in case they don't exist (will cause ignorable error if index already exist"
#curl -XPUT "http://localhost:9200/filebeat-$(date +'%Y%m%d')-dummy"
curl -XPUT "http://localhost:9200/core-$(date +'%Y.%m')"
curl -XPUT "http://localhost:9200/aux-$(date +'%Y.%m')"

# add aliases for indexes
echo "adding aliasses for indexes"
curl -XPOST 'http://localhost:9200/_aliases' -d '{ "actions" : [ { "add" : { "index" : "filebeat-*", "alias" : "core" } } ] }'
curl -XPOST 'http://localhost:9200/_aliases' -d '{ "actions" : [ { "add" : { "index" : "core-*", "alias" : "core" } } ] }'
#curl -XPOST 'http://localhost:9200/_aliases' -d '{ "actions" : [ { "add" : { "index" : "aux-*", "alias" : "aux" } } ] }'
curl -XPOST 'http://localhost:9200/_aliases' -d '{ "actions" : [ { "add" : { "index" : "*-*", "alias" : "all" } } ] }'

# import index patterns in kibana
echo "import index patterns in kibana"
curl -XPUT 'http://localhost:9200/.kibana/index-pattern/core' -d '{"title" : "core", "timeFieldName" : "@timestamp"}'
#curl -XPUT 'http://localhost:9200/.kibana/index-pattern/aux' -d '{"title" : "aux", "timeFieldName" : "@timestamp"}'
curl -XPUT 'http://localhost:9200/.kibana/index-pattern/aux' -d '{"title" : "aux-*", "timeFieldName" : "@timestamp"}'
curl -XPUT 'http://localhost:9200/.kibana/index-pattern/all' -d '{"title" : "all", "timeFieldName" : "@timestamp"}'

# set default pattern in kibana
echo "set default index patterns in kibana"
curl -XPUT http://localhost:9200/.kibana/config/5.2.0 -d '{"defaultIndex" : "core", "discover:sampleSize:" : "10000" }'

touch $OUTPUT_LOGFILES
tail -f $OUTPUT_LOGFILES &
wait
