#!/bin/sh

set -e

echo "$1"

route_uri="$1"
host="$2"

# UDP routes have no connection handshake, so probing with nc -u is unreliable
# and can block logspout startup even when Logstash is healthy.
case "$route_uri" in
  *"+tcp://"*|*"+tls://"*)
    a=0
    while [ "$a" -lt 20 ]
    do
      if nc -z -v "$host" 5000 >/dev/null 2>&1; then
        echo "server reachable"
        exec /bin/logspout "$route_uri"
      fi
      echo "server not reachable"
      sleep 10
      a=`expr "$a" + 1`
    done
    exit 1
    ;;
  *)
    echo "starting without preflight check for UDP route"
    exec /bin/logspout "$route_uri"
    ;;
esac

