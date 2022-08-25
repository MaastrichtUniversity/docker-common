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
externals/dh-mailer  https://github.com/MaastrichtUniversity/dh-mailer.git
externals/dh-fail2ban https://github.com/MaastrichtUniversity/dh-fail2ban.git
externals/dh-home https://github.com/MaastrichtUniversity/dh-home.git"

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
create_networks

# Create volumes
if [ ! $(docker volume ls --filter name=corpus_static_content --format="true") ] ;
      then
       echo "Creating volume corpus_static_content"
       docker volume create --name=corpus_static_content
fi

if [ ! $(docker volume ls --filter name=corpus_webdav_logs --format="true") ] ;
      then
       echo "Creating volume corpus_webdav_logs"
       docker volume create --name=corpus_webdav_logs
fi

if [ ! $(docker volume ls --filter name=corpus_upload_logs --format="true") ] ;
      then
       echo "Creating volume corpus_upload_logs"
       docker volume create --name=corpus_upload_logs
fi


# Assuming docker-compose is available in the PATH
log $DBG "$0 [docker-compose \"$ARGS\"]"
docker-compose $ARGS

