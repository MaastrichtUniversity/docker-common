FROM jasonrivers/nagios:4.3.2

#
# Install check_atlassian (for monitoring licenses of Atlassian products)
#
RUN cd /opt/Custom-Nagios-Plugins/ && \
    wget https://raw.githubusercontent.com/AmadeusITGroup/monitoring-plugins/master/check_atlassian && \
    chmod 755 /opt/Custom-Nagios-Plugins/check_atlassian && \
    cpan && \
    cpan LWP::Simple


# Add slightly modified config for nagiosgraph (locations set to external volume for persistence)
ADD ./nagiosgraph.conf /opt/nagiosgraph/etc/nagiosgraph.conf

# Add script to reload nagios config from within container
ADD ./nagios-reload /usr/local/bin/nagios-reload

# Add some additional icons and images
ADD ./img/docker.png /opt/nagios/share/images/logos/


EXPOSE 80



#ENTRYPOINT ["/bin/bootstrap.sh"]
CMD [ "/usr/local/bin/start_nagios" ]