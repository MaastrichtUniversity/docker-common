FROM sebp/elk:531

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
RUN /opt/kibana/bin/kibana-plugin install https://github.com/sivasamyk/logtrail/releases/download/0.1.11/logtrail-5.3.1-0.1.11.zip
ADD logtrail.json /opt/kibana/plugins/logtrail/logtrail.json
### Bug fix for logtrail https://github.com/sivasamyk/logtrail/issues/20
ADD logtrail_server.js /opt/kibana/plugins/logtrail/server/routes/server.js
ADD logtrail_app.js /opt/kibana/plugins/logtrail/public/app.js

### overwrite nagios patterns with own fork of Elastic logstash-patterns because of missing Nagios patterns
RUN cd /opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-4.1.2/patterns/        && \
    curl -O https://raw.githubusercontent.com/MaastrichtUniversity/logstash-patterns-core/master/patterns/nagios && \
    chmod 644 nagios                                                                            && \
    chown logstash:logstash nagios

# Remove existing config files
RUN rm -r /etc/logstash/conf.d/ && mkdir /etc/logstash/conf.d/

# Add config files
ADD logstash-config/*.conf /etc/logstash/conf.d/

ADD ./RIT.pattern ${LOGSTASH_HOME}/patterns/RIT
ADD ./kibana-exported.json /tmp/kibana-exported.json


## Reverse proxy for default site with password
ADD 000-default.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 5000 5001 80

# Create own startup script
ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Create retention script and schedule
ADD ./retention.sh /etc/cron.monthly/retention.sh
ADD ./cron_retention /etc/cron.d/cron_retention
RUN chmod +x /etc/cron.monthly/retention.sh


###filebeat template
ADD ./template.*.json /tmp/

CMD [ "/usr/local/bin/start.sh" ]
