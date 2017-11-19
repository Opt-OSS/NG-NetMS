#!/bin/sh

#DEBUG=echo


#------------------------------------------------------------
# Default options
#------------------------------------------------------------
VERBOSE="-v 1"

BIN_DIR=${NGNMS_HOME}/bin
LOG_DIR=${NGNMS_LOGS}

#------------------------------------------------------------
# Service options
#------------------------------------------------------------

COLLECTOR_UDP_OPTIONS="-s syslog-udp -p 514 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-log.txt -l $LOG_DIR/syslog_collector.log"
COLLECTOR_SNMP_OPTIONS="-s snmp-polling -c $BIN_DIR/db.cfg -f /var/log/snmptraps.log -r $NGNMS_HOME/rules/rules-snmp.txt -l $LOG_DIR/snmp_collector.log"
COLLECTOR_NFLOW_OPTIONS="-s netflow-udp -p 2055 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-netflow.txt -l $LOG_DIR/netflow_collector.log"

OBSERVER_OPTIONS="$VERBOSE -m -c $BIN_DIR/options.json -o $BIN_DIR/db.cfg -l $LOG_DIR/observer.log"
OPTION_PROFILER="$VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/optprf.log" 


#------------------------------------------------------------
# Options Profiler functions
#------------------------------------------------------------
op_initdb()
{
    op_stop
    $DEBUG $BIN_DIR/ngnetms_opt_prf -d $OPTION_PROFILER &
    sleep 1
    echo "\n Init Profiler DB tables"
}

op_start()
{
# Options Profiler to be started last in base group of services

    echo "\n Starting options profiler..."
    $DEBUG $BIN_DIR/ngnetms_opt_prf $OPTION_PROFILER &
    sleep 1 
    echo "\n started"
}

op_stop()
{
    $DEBUG sudo killall ngnetms_opt_prf
    sleep 1
    echo "\n options profiler stopped"
}

op_status()
{
    echo "\tOptions profiler:"
    $DEBUG ps -ax | grep /[n/]gnetms_opt_prf >&2
}

op_restart()
{
   op_stop
   op_start
}


#------------------------------------------------------------
# Collector functions
#------------------------------------------------------------
c_start()
{
    [ -z "$1" ] || {
        echo "Custom options can not be applied to the both collector servies. Options ignored."
    }
    #Collectors sould be started 1st
    echo "\n Starting collectors..."
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_UDP_OPTIONS &
    sleep 1
    echo "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_SNMP_OPTIONS  &
    sleep 1 
    echo "\n started"
}

c_stop()
{
    $DEBUG sudo killall ngnetms_collector
    sleep 2
    echo "\n ngnetms collectors stopped"
}

c_restart()
{
    c_stop
    sleep 1
    c_start "$1"
    echo "\n ngnetms collectors restarted"
}

c_status()
{
    echo "\tCollector:"
    $DEBUG ps -ax | grep /[n/]gnetms_collector >&2
}


#------------------------------------------------------------
# Observer functions
#------------------------------------------------------------
o_initdb()
{
    o_stop
    $DEBUG sudo $BIN_DIR/ngnetms_observer -D $OBSERVER_OPTIONS &
    sleep 1
    echo "\n Init Observer DB tables"
}

o_start()
{
    [ -z "$1" ] || {
        OBSERVER_OPTIONS=$1
    }

    echo "\n Starting observer"
    $DEBUG sudo $BIN_DIR/ngnetms_observer $OBSERVER_OPTIONS &
    sleep 1
    echo "\n started"
}

o_stop()
{
    $DEBUG sudo killall ngnetms_observer
    sleep 1
    echo "\n ngnetms observer stopped"
}

o_restart()
{
    o_stop
    o_start "$1"
}

o_status()
{
	echo "\tObserver:"
    $DEBUG ps -ax | grep /[n/]gnetms_observer >&2
}






#------------------------------------------------------------
# NGNMS (all services) functions
#------------------------------------------------------------

n_initdb()
{

#    echo "\n Initialising DB for observer NGNMS services"
#    o_initdb
#    sleep 1
#    op_initdb
#    sleep 1


    n_stop
}

n_start()
{
    echo "\n Starting base ngnms services"
    c_start
    o_start
    op_start
}

n_stop()
{
    echo "\n Stopping All ngnms services"
    c_stop
    o_stop
    op_stop
    echo "\n Done."
}

n_restart()
{
    n_stop
    sleep 2
    n_start
}

n_status()
{
	echo ""
    c_status
    o_status
    op_status
	echo ""
}


#------------------------------------------------------------
# Help function
#------------------------------------------------------------
print_help()
{
    echo "Usage:"
    echo "  $1 start [\"options\"]   Start $1 servise"
    echo "  $1 stop                Stop $1 servise"
    echo "  $1 restart [\"options\"] Restart $1 servise"
    echo "  $1 initdb [\"options\"] Init DB tables for $1 servise"
    echo "  $1 status              Status of $1 servise"
}


#------------------------------------------------------------
# Command line case analysis
#------------------------------------------------------------

do_case()
{
case $service in
    "collector") case $action in
            "start") c_start "$options";;
            "stop") c_stop;;
            "restart") c_restart "$options";;
            "status") c_status;;
            *)  print_help $service;;
        esac
    ;;
    "observer") case $action in
            "initdb") o_initdb "$options";;
            "start") o_start "$options";;
            "stop") o_stop;;
            "restart") o_restart "$options";;
            "status") o_status;;
            *)  print_help $service;;
        esac
    ;;
    "ngnetms") case $action in
            "start") n_start "$options";;
            "stop") n_stop;;
            "restart") n_restart "$options";;
            "status") n_status;;
            "initdb") n_initdb;;
            *)  print_help $service;;
        esac
    ;;
    "optprf") case $action in
            "initdb") op_initdb "$options";;
            "start") op_start "$options";;
            "stop") op_stop;;
            "restart") op_restart "$options";;
            "status") op_status;;
            *)  print_help $service;;
        esac
    ;;
    *)  echo "Usage:"
        echo "  <collector|ngnms|observer|optprf> <start|stop|restart|initdb|status> [\"options\"]"
        ;;
esac

}

#------------------------------------------------------------
# Main part
#------------------------------------------------------------
service=$1
action=$2
options=$3

do_case
