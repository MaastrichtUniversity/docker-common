#!/usr/bin/env bash

# source library lib-dh.sh
if [[ -z $DH_ENV_HOME ]]; then
    DH_ENV_HOME=".."
    echo "(DH_ENV_HOME not set, using parent folder as default)"
fi
. $DH_ENV_HOME/lib-dh.sh

# Set logging level based on -v (--verbose) or -vv param
ARGS="$@ "
if [[ ${ARGS} = *"-vv "* ]]; then
   export LOGTRESHOLD=$DBG
   ARGS="${ARGS/-vv /}"
elif [[ ${ARGS} = *"--verbose "* ]] || [[ ${ARGS} = *"-v "* ]]; then
   export LOGTRESHOLD=$INF
   ARGS="${ARGS/--verbose /}"
   ARGS="${ARGS/-v /}"
fi

# Set the prefix for the project
COMPOSE_PROJECT_NAME="common"
export COMPOSE_PROJECT_NAME

set -e

# specify externals for this project
externals="externals/nagios-docker https://github.com/MaastrichtUniversity/nagios-docker.git
externals/elastalert-docker  https://github.com/MaastrichtUniversity/elastalert-docker.git
externals/dh-fail2ban https://github.com/MaastrichtUniversity/dh-fail2ban.git"

# do the required action in case of externals or exec
if [[ $1 == "externals" ]]; then
    action=${ARGS/$1/}
    run_repo_action ${action} "${externals}"
    exit 0
fi

if [[ $1 == "exec" ]]; then
    run_docker_exec ${COMPOSE_PROJECT_NAME} $2
    exit 0
fi

if [[ $1 == "login" ]]; then
    source './.env'
    docker login $ENV_REGISTRY_HOST
    exit 0
fi

# set RIT_ENV if not set already
env_selector

# Create networks
if ! docker network inspect dh_public > /dev/null 2>&1; then
       docker network create dh_public --subnet "172.22.1.0/24" --label "com.docker.compose.project"="dev" --label "com.docker.compose.network"="dh_public"
fi

if ! docker network inspect dh_default > /dev/null 2>&1; then
       docker network create dh_default --subnet "172.21.1.0/24" --label "com.docker.compose.project"="dev" --label "com.docker.compose.network"="default"
fi

if [ ! $(docker network ls --filter name=dev-hdp_hdp-dh-mumc-net --format="true") ]; then
  echo "Creating network dev-hdp_hdp-dh-mumc-net"
  docker network create dev-hdp_hdp-dh-mumc-net --subnet "172.32.1.0/24" --label "com.docker.compose.project"="dev-hdp" --label "com.docker.compose.network"="hdp-dh-mumc-net"
fi


if [ ! $(docker network ls --filter name=dev-hdp_hdp-dh-zio-net --format="true") ]; then
  echo "Creating network dev-hdp_hdp-dh-zio-net"
  docker network create dev-hdp_hdp-dh-zio-net --subnet "172.33.1.0/24" --label "com.docker.compose.project"="dev-hdp" --label "com.docker.compose.network"="hdp-dh-zio-net"
fi

if [ ! $(docker network ls --filter name=dev-hdp_hdp-dh-envida-net --format="true") ]; then
  echo "Creating network dev-hdp_hdp-dh-envida-net"
  docker network create dev-hdp_hdp-dh-envida-net --subnet "172.34.1.0/24" --label "com.docker.compose.project"="dev-hdp" --label "com.docker.compose.network"="hdp-dh-envida-net"
fi

# Create volumes
if [ ! $(docker volume ls --filter name=dev_static_content --format="true") ] ;
      then
       echo "Creating volume dev_static_content"
       docker volume create --name=dev_static_content
fi

if [ ! $(docker volume ls --filter name=dev_webdav_logs --format="true") ] ;
      then
       echo "Creating volume dev_webdav_logs"
       docker volume create --name=dev_webdav_logs
fi

if [ ! $(docker volume ls --filter name=dev_upload_logs --format="true") ] ;
      then
       echo "Creating volume dev_upload_logs"
       docker volume create --name=dev_upload_logs
fi


# Assuming docker-compose is available in the PATH
log $DBG "$0 [docker-compose \"$ARGS\"]"
docker compose $ARGS

