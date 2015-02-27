#!/bin/bash
# this srcipt automatically starts or stops event monitoring in NGNMS3.0
# it has to be launched from $NGNMS_HOME/bin directory
#
echo -n

case "$1" in

start)
	/home/ngnms/NGREADY/bin/ngnms_collector -u -p 514 -o /home/ngnms/NGREADY/bin/db.cfg -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/syslog_collector.log > /dev/null 2>&1 &
	/home/ngnms/NGREADY/bin/ngnms_collector -c snmp -o /home/ngnms/NGREADY/bin/db.cfg -i /var/log/snmptraps.log -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/snmp_collector.log > /dev/null 2>&1 &
	;;

stop)
	killall ngnms_collector && echo -n '   ngnms'
	;;

status)
	echo "-n"
	ps -ax | grep ngnms_collector
	;;
*)
	echo "Usage: `basename $0` {start|stop}" >&2
	;;

esac

exit 0

