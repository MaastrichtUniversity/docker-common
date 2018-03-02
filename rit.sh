#!/usr/bin/env bash

set -e


externals=""

if [[ $1 == "externals" ]]; then
    mkdir -p externals

    if [[ $2 == "clone" ]]; then
        # Ignore error during cloning, as we don't care about existing dirs
        set +e
        while read -r external; do
            external=($external)
            echo -e "\e[32m =============== ${external[0]} ======================\033[0m"
            git clone ${external[1]} ${external[0]}
        done <<< "$externals"
    fi

    if [[ $2 == "status" ]]; then
        while read -r external; do
            external=($external)
            echo -e "\e[32m =============== ${external[0]} ======================\033[0m"
            git -C ${external[0]} status
        done <<< "$externals"
    fi

    if [[ $2 == "pull" ]]; then
        while read -r external; do
            external=($external)
            echo -e "\e[32m =============== ${external[0]} ======================\033[0m"
            git -C ${external[0]} pull --rebase
        done <<< "$externals"
    fi
    exit 0
fi

if [[ $1 == "exec" ]]; then
    echo "Connect to container instance : $2"
    docker exec -it $2 env COLUMNS=$(tput cols) LINES=$(tput lines) /bin/bash
    exit 0
fi

if [[ -z $RIT_ENV ]]; then
    RIT_ENV="local"

    if [[ $HOSTNAME == "fhml-srv018" ]]; then
        RIT_ENV="tst"
    fi

    if [[ $HOSTNAME == "fhml-srv019" ]]; then
        RIT_ENV="dev1"
    fi

    if [[ $HOSTNAME == "fhml-srv020" ]]; then
        RIT_ENV="dev2"
    fi

    if [[ $HOSTNAME == "fhml-srv065" ]]; then
        RIT_ENV="dev3"
    fi

fi
export RIT_ENV

# Create networks

if ! docker network inspect corpus_default > /dev/null 2>&1; then
   docker network create corpus_default
fi
if ! docker network inspect oculus_default > /dev/null 2>&1; then
   docker network create oculus_default
fi

# Set the prefix for the project
COMPOSE_PROJECT_NAME="common"
export COMPOSE_PROJECT_NAME

# Assuming docker-compose is available in the PATH
docker-compose "$@"
