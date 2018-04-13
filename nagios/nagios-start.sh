#!/bin/sh

echo Starting Nagios container...

docker run --name common_nagios_1  \
  -v $(pwd)/var:/opt/nagios/var \
  -v $(pwd)/etc:/opt/nagios/etc:ro \
  -v $(pwd)/cust-plugins:/opt/Custom-Nagios-Plugins:ro \
  -v $(pwd)/nagiosgraph.conf:/opt/nagiosgraph/etc/nagiosgraph.conf:ro \
  -p 0.0.0.0:8080:80 \
  $1 \
  jasonrivers/nagios:latest 

echo ...done
echo
echo Config can be found under ~/nagios/etc
echo Logs can be found under ~/nagios/var
echo
echo Opening shell in Nagios container:
echo   - docker exec -it common_nagios_1 bash
echo
echo Restarting nagios e.g. to read modified config:
echo   - ~/nagios/nagios-restart.sh
echo
echo Stopping nagios:
echo  - ~/nagios.nagios-stop.sh
echo

exit 0;
