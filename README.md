# Docker-common

Common containers for the RIT development environment. These containers are shared amongst ``docker-compose`` projects from:
* docker-dev

**Note:** Please note that the ``proxy`` container is required to access services from other compose-projects by ``VIRTUAL_HOST`` address.


## Requirements

### Runtime configuration
To prevent this [runtime issue](https://github.com/docker-library/elasticsearch/issues/111), increase maximum memory on the docker-host machine:
```
sudo sysctl -w vm.max_map_count=262144
```

### Download GeoLite database
GeoLite2 is used to retrieve geolocation of IP-addresses. Since the end of 2019, Maxmind [has changed its license model](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/) and stopped providing public access.
Therefore, you need to obtain the database manually and place it in the `elk/` folder to allow the docker build process to add the file to the container.

### Get lib-dh.sh
Download `lib-dh.sh` from [dh-env repository](https://github.com/MaastrichtUniversity/dh-env) and place it one level before `docker-common`.

### Encryption between filebeat and elk

CA certificates need to be manually stored in folder `elk/certs`.
The present files are used for development-purposes.


## Run
```
# Get external repositories
./rit.sh externals clone

# Run the main project
./rit.sh build
./rit.sh down
./rit.sh up

# Run the nagios service
./rit.sh -f nagios-docker-compose.yml build
./rit.sh -f nagios-docker-compose.yml down
./rit.sh -f nagios-docker-compose.yml up

# Run the elk5 service
./rit.sh -f elk5-docker-compose.yml build
./rit.sh -f elk5-docker-compose.yml down
./rit.sh -f elk5-docker-compose.yml up

# Run ``proxy`` container only
./rit.sh build proxy
./rit.sh up proxy
```

## Run elk for HDP services

### Extra requirements

* Add this virtual host entry in your `/etc/hosts` file
```
127.0.0.1 elk.local.dh.unimaas.nl
```
* Run the "proxy" container from docker-health: `./dh.sh up -d proxy`


### Run elk services

* In docker-common, build and up the following containers:
```
./rit.sh build elk
./rit.sh build logspout

./rit.sh up -d elk
./rit.sh up -d logspout
```

* Open your browser and try [http://elk.local.dh.unimaas.nl](http://elk.local.dh.unimaas.nl) with credentials:
```
ELASTIC_USERNAME: elastic
ELASTIC_PASSWORD: foobar
```

* Run code in docker-health such as `./dh.sh zib` to see logs appearing on the elk server.
