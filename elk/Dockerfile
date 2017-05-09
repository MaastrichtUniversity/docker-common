FROM sebp/elk:520

ENV LOGSTASH_HOME /opt/logstash

WORKDIR ${LOGSTASH_HOME}
RUN gosu logstash bin/logstash-plugin install logstash-patterns-core
RUN gosu logstash bin/logstash-plugin install logstash-input-beats

RUN cd /etc/logstash && \
    curl -O "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz" && \
    gunzip GeoLite2-City.mmdb.gz

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    npm \
    apache2 \
    nano
RUN npm install -g elasticdump
RUN ln -s /usr/bin/nodejs /usr/bin/node

###Logtrail
RUN /opt/kibana/bin/kibana-plugin install https://github.com/sivasamyk/logtrail/releases/download/0.1.8/logtrail-5.2.0-0.1.8.zip
ADD logtrail.json /opt/kibana/plugins/logtrail/logtrail.json
### Bug fix for logtrail https://github.com/sivasamyk/logtrail/issues/20
ADD logtrail_server.js /opt/kibana/plugins/logtrail/server/routes/server.js
ADD logtrail_app.js /opt/kibana/plugins/logtrail/public/app.js

# Add config files
ADD DWH_FRONTEND.conf /etc/logstash/conf.d/FRONTEND.conf
ADD ICAT.conf /etc/logstash/conf.d/ICAT.conf
ADD IRES.conf /etc/logstash/conf.d/IRES.conf
ADD IRODS_FRONTEND.conf /etc/logstash/conf.d/IRODS_FRONTEND.conf
ADD METALNX.conf /etc/logstash/conf.d/METALNX.conf
ADD MIRTH.conf /etc/logstash/conf.d/MIRTH.conf
ADD PACMAN.conf /etc/logstash/conf.d/PACMAN.conf
ADD PROXY.conf /etc/logstash/conf.d/PROXY.conf
ADD SOLR.conf /etc/logstash/conf.d/SOLR.conf
ADD DAVRODS.conf /etc/logstash/conf.d/DAVRODS.conf
ADD 02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf
ADD 30-output.conf /etc/logstash/conf.d/30-output.conf

ADD ./RIT.pattern ${LOGSTASH_HOME}/patterns/RIT
ADD ./kibana-exported.json /tmp/kibana-exported.json


## Reverse proxy for default site with password
ADD 000-default.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 5000 80

#Create own startup script
ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

###filebeat template
ADD ./filebeat.template.json /tmp/filebeat.template.json

CMD [ "/usr/local/bin/start.sh" ]
