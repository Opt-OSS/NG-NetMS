#!/bin/bash
# NG-NetMS, a Next Generation Network Managment System
# 
# Version 3.3 
# Build number N/A
# Copyright (C) 2015 Opt/Net
# 
# This file is part of NG-NetMS tool.
# 
# NG-NetMS is free software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License v3.0 as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# NG-NetMS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
# See the GNU General Public License for more details. You should have received a copy of the GNU
# General Public License along with NG-NetMS. If not, see <http://www.gnu.org/licenses/gpl-3.0.html>.
# 
# Authors: T.Matselyukh, D. Danylchenko
 
# this srcipt automatically starts or stops event monitoring and profiling in NGNMS3.3
# it has to be launched from $NGNMS_HOME/bin directory
#
echo -n

case "$1" in

start)
	. /etc/environment
	export PATH NGNMS_HOME NGNMS_CONFIGS PERL5LIB MIBDIRS
#	/home/ngnms/NGREADY/bin/ngnetms_profiler -j -a1 -o /home/ngnms/NGREADY/bin/db.cfg -l /home/ngnms/NGREADY/logs/syslog_collector.log > /dev/null 2>&1 &
	/home/ngnms/NGREADY/bin/ngnetms_collector -u -p 514 -o /home/ngnms/NGREADY/bin/db.cfg -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/syslog_collector.log > /dev/null 2>&1 &
	/home/ngnms/NGREADY/bin/ngnetms_collector -c snmp -o /home/ngnms/NGREADY/bin/db.cfg -i /var/log/snmptraps.log -r /home/ngnms/NGREADY/rules/rules.txt -l /home/ngnms/NGREADY/logs/snmp_collector.log > /dev/null 2>&1 &
	;;

stop)
	killall ngnetms_collector && echo -n '   ngnms'
#	killall ngnetms_profiler && echo -n '   ngnms'
	;;

status)
	echo "-n"
	ps -ax | grep ngnetms_collector
#	ps -ax | grep ngnetms_profiler
	;;
*)
	echo "Usage: `basename $0` {start|stop}" >&2
	;;

esac

exit 0

