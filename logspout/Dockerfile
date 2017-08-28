FROM gliderlabs/logspout:v3.2.2
ENV SYSLOG_FORMAT rfc3164
ADD ./bootstrap.sh /bin/bootstrap.sh
RUN chmod a+x /bin/bootstrap.sh


ENTRYPOINT ["/bin/bootstrap.sh"]