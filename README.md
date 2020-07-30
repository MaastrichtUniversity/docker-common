# Docker-common

Common containers for the RIT development environment. These containers are shared amongst ``docker-compose`` projects from:
* docker-dev

**Note:** Please note that the ``proxy`` container is required to access services from other compose-projects by ``VIRTUAL_HOST`` address.

## Config
* To prevent this [runtime issue](https://github.com/docker-library/elasticsearch/issues/111), increase maximum memory on the docker-host machine:
```
sudo sysctl -w vm.max_map_count=262144
```

## GeoLite database
GeoLite2 is used to retrieve geolocation of IP-addresses. Since the end of 2019, Maxmind [has changed its license model](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/) and stopped providing public access.
Therefore, you need to obtain the database manually and place it in the `elk/` and `elk5/` folders to allow the docker build process to add the file to the container. 

## Get external repositories

```
./rit.sh externals clone
```

## Run
```
# Run the main project
./rit.sh build
./rit.sh down
./rit.sh up

# Run the nagios service
./rit.sh -f nagios-docker-compose.yml build
./rit.sh -f nagios-docker-compose.yml down
./rit.sh -f nagios-docker-compose.yml up
```

# Run the elk5 service
./rit.sh -f elk5-docker-compose.yml build
./rit.sh -f elk5-docker-compose.yml down
./rit.sh -f elk5-docker-compose.yml up
```

## Run ``proxy`` container only
```
./rit.sh build proxy
./rit.sh up proxy
```

