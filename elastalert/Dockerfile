FROM ivankrizsan/elastalert

#
# install send_nrdp for passive checks
#
RUN cd /tmp/ && \
    wget https://github.com/NagiosEnterprises/nrdp/archive/1.5.2.tar.gz && \
    tar xvf 1.5.2.tar.gz && \
    cd nrdp-* && \
    mkdir /usr/local/nrdp && \
    cp -r clients /usr/local/nrdp && \
#    chown -R nagios:nagios /usr/local/nrdp && \
    rm -rf /tmp/nrdp-*


#copy the modified start script
ADD ./start-elastalert.sh /usr/local/bin/start.sh

#
# For development time, install bash
#
#TODO: this must be removed before commiting for prudcution
#
RUN apk update && apk add bash


CMD [ "/usr/local/bin/start.sh" ]
