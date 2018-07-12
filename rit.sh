#!/usr/bin/env bash
echo "$0 $@  [START, running in $(pwd)]"

# source library dh-lib.sh
if [[ -z $DH_ENV_HOME ]]; then
    DH_ENV_HOME=".."
    echo "(DH_ENV_HOME not set, using parent folder as default)"
fi
. $DH_ENV_HOME/dh-lib.sh


# Set the prefix for the project
COMPOSE_PROJECT_NAME="common"
export COMPOSE_PROJECT_NAME

set -e

# specify externals for this project
externals=""

# do the required action in case of externals or exec
if [[ $1 == "externals" ]]; then
    action=$2
    run_repo_action ${action} "${externals}"
    exit 0
fi

if [[ $1 == "exec" ]]; then
    run_docker_exec ${COMPOSE_PROJECT_NAME} $2
    exit 0
fi

# set RIT_ENV if not set already
env_selector

# Create networks
if ! docker network inspect corpus_default > /dev/null 2>&1; then
   docker network create corpus_default
fi
if ! docker network inspect oculus_default > /dev/null 2>&1; then
   docker network create oculus_default
fi

# Assuming docker-compose is available in the PATH
log $DBG "$0 [docker-compose \"$@\"]"
docker-compose "$@"

