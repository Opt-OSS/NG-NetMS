#!/bin/bash
echo -n

case "$1" in

start)
	. /etc/environment
	export PATH NGNMS_HOME NGNMS_CONFIGS PERL5LIB MIBDIRS
	/home/ngnms/NGREADY/bin/ngnetms_collector -u -p 514 -o /home/ngnms/NGREADY/bin/db.cfg -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/syslog_collector.log > /dev/null 2>&1 &
	/home/ngnms/NGREADY/bin/ngnetms_collector -c snmp -o /home/ngnms/NGREADY/bin/db.cfg -i /var/log/snmptraps.log -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/snmp_collector.log > /dev/null 2>&1 &
	;;

stop)
	killall ngnetms_collector && echo -n '   ngnms'
	;;

status)
	echo "-n"
	ps -ax | grep ngnetms_collector
	;;
*)
	echo "Usage: `basename $0` {start|stop}" >&2
	;;

esac

exit 0

