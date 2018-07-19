FROM sebp/elk:520

ENV LOGSTASH_HOME /opt/logstash

WORKDIR ${LOGSTASH_HOME}
RUN gosu logstash bin/logstash-plugin install logstash-patterns-core
RUN gosu logstash bin/logstash-plugin update logstash-patterns-core
RUN gosu logstash bin/logstash-plugin install logstash-input-beats

RUN cd /etc/logstash && \
    curl -O "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz" && \
    gunzip GeoLite2-City.mmdb.gz

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    npm \
    apache2 \
    nano
RUN npm install -g elasticdump@3.3.3
RUN ln -s /usr/bin/nodejs /usr/bin/node

###Logtrail
RUN /opt/kibana/bin/kibana-plugin install https://github.com/sivasamyk/logtrail/releases/download/0.1.8/logtrail-5.2.0-0.1.8.zip
ADD logtrail.json /opt/kibana/plugins/logtrail/logtrail.json
### Bug fix for logtrail https://github.com/sivasamyk/logtrail/issues/20
ADD logtrail_server.js /opt/kibana/plugins/logtrail/server/routes/server.js
ADD logtrail_app.js /opt/kibana/plugins/logtrail/public/app.js

# Remove existing config files
RUN rm -r /etc/logstash/conf.d/ && mkdir /etc/logstash/conf.d/

# Add config files
ADD logstash-config/*.conf /etc/logstash/conf.d/

ADD ./RIT.pattern ${LOGSTASH_HOME}/patterns/RIT
ADD ./kibana-exported.json /tmp/kibana-exported.json


## Reverse proxy for default site with password
ADD 000-default.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 5000 5001 80

#Create own startup script
ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

###filebeat template
ADD ./filebeat.template.json /tmp/filebeat.template.json

CMD [ "/usr/local/bin/start.sh" ]
