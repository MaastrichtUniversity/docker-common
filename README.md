# Docker-common

Common containers for the RIT development environment. These containers are shared amongst ``docker-compose`` projects from:
* docker-dev
* docker-oculus

**Note:** Be sure to start at least the ``proxy`` container before starting services from the other compose-projects.

## Config
* To prevent this [runtime issue](https://github.com/docker-library/elasticsearch/issues/111), increase maximum memory on the docker-host machine:
```
sudo sysctl -w vm.max_map_count=262144
```

## Get external repositories

```
./rit.sh externals clone
```

## Run
```
./rit.sh build
./rit.sh down
./rit.sh up
```

## Run ``proxy`` container only
```
./rit.sh build proxy
./rit.sh up proxy
```

