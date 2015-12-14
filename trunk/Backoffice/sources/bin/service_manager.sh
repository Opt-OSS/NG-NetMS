#!/bin/sh

#DEBUG=echo

BIN_DIR=/home/ngnms/NGREADY/bin
LOG_DIR=/home/ngnms/NGREADY/logs

#------------------------------------------------------------
# Default serveces options
#------------------------------------------------------------
COLLECTOR_UDP_OPTIONS="-u -p 514 -o $BIN_DIR/db.cfg -r /home/ngnms/NGREADY/rules/rules.txt -l $LOG_DIR/syslog_collector.log"
COLLECTOR_SNMP_OPTIONS="-c snmp -o $BIN_DIR/db.cfg -i /var/log/snmptraps.log -r /home/ngnms/NGREADY/rules/rules.txt -l $LOG_DIR/snmp_collector.log"
PROFILER_OPTIONS="-j -a 9 -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log"
DETECTOR_OPTIONS="-j -L 105 -m 1000 -d 10 -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log"
OBSERVER_OPTIONS="-m -c $BIN_DIR/options.json -o $BIN_DIR/db.cfg -l $LOG_DIR/observer.log"
MQ_SIZE=1000

OPTION_PROFILER=" -o $BIN_DIR/db.cfg -l $LOG_DIR/optprf.log &" 

#------------------------------------------------------------
# Options Profiler functions
#------------------------------------------------------------
op_start()
{
    $DEBUG $BIN_DIR/ngnetms_opt_prf $OPTION_PROFILER &
}

op_stop()
{
    $DEBUG sudo killall ngnetms_opt_prf
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
        echo "Custom options can not be applied to the both servies. Options ignored."
    }

    #Detector sould be started 1st
    echo "\n Start collectors"
    $DEBUG sudo $BIN_DIR/ngnetms_collector $COLLECTOR_UDP_OPTIONS &
    $DEBUG sudo $BIN_DIR/ngnetms_collector $COLLECTOR_SNMP_OPTIONS  &

}

c_stop()
{
    $DEBUG sudo killall ngnetms_collector
}

c_restart()
{
    c_stop
    c_start "$1"
}

c_status()
{
    $DEBUG ps -ax | grep ngnetms_collector >&2
}


#------------------------------------------------------------
# Profiler functions
#------------------------------------------------------------
p_start()
{
    [ -z "$1" ] || {
        PROFILER_OPTIONS=$1
    }
    echo "\n Start profiler"
    $DEBUG sudo $BIN_DIR/ngnetms_profiler $PROFILER_OPTIONS &
}

p_stop()
{
    $DEBUG sudo killall ngnetms_profiler
}

p_restart()
{
    p_stop
    p_start "$1"
}

p_status()
{
    $DEBUG ps -ax | grep ngnetms_profiler >&2
}


#------------------------------------------------------------
# Detector functions
#------------------------------------------------------------
d_start()
{
    [ -z "$1" ] || {
        DETECTOR_OPTIONS=$1
    }

    echo "\n Start detector"
    $DEBUG sudo $BIN_DIR/ngnetms_detector $DETECTOR_OPTIONS &
}

d_stop()
{
    $DEBUG sudo killall ngnetms_detector
}

d_restart()
{
    d_stop
    d_start "$1"
}

d_status()
{
    $DEBUG ps -ax | grep ngnetms_detector >&2
}

#------------------------------------------------------------
# Observer functions
#------------------------------------------------------------
o_start()
{
    [ -z "$1" ] || {
        OBSERVER_OPTIONS=$1
    }

    echo "\n Start observer"
    $DEBUG sudo $BIN_DIR/ngnetms_observer $OBSERVER_OPTIONS & 
}

o_stop()
{
    $DEBUG sudo killall ngnetms_observer
}

o_restart()
{
    o_stop
    o_start "$1"
}

o_status()
{
    $DEBUG ps -ax | grep ngnetms_observer >&2
}


#------------------------------------------------------------
# Anomaly (profiler & detector) functions
#------------------------------------------------------------
a_start()
{
    mq_size=`cat /proc/sys/fs/mqueue/msg_max`
    [ $mq_size -eq $MQ_SIZE ] || {
        $DEBUG sudo su root -c "echo $MQ_SIZE > /proc/sys/fs/mqueue/msg_max"
    }

    #Detector sould be started 1st
    d_start
    sleep 3
    #Profiler shoul be started 2nd
    p_start
}

a_stop()
{
    p_stop
    d_stop
}

a_restart()
{
    a_stop
    a_start
}

a_dump()
{
    pg_dump --data-only --table=public.anomaly ngnms > /home/ngnms/NGREADY/data/anomaly.db
    pg_dump --data-only --table=public.anomaly_template ngnms > /home/ngnms/NGREADY/data/anomaly_template.db
}

a_restore()
{
    $DEBUG psql --table=public.anomaly -d ngnms < /home/ngnms/NGREADY/data/anomaly.db
    $DEBUG psql --table=public.anomaly_template -d ngnms < /home/ngnms/NGREADY/data/anomaly_template.db
}

a_recreate()
{
    a_stop
    a_dump
    $DEBUG $BIN_DIR/anomaly_detector -D -j -L $level -m $max -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log &
    sleep 2
    a_restore
    $DEBUG $BIN_DIR/ngnetms_profiler -D -a $algorithm -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log &
}

a_status()
{
    p_status
    d_status
}


#------------------------------------------------------------
# NGNMS (all services) functions
#------------------------------------------------------------
n_start()
{
    c_start
    a_start
    o_start
}

n_stop()
{
    c_stop
    a_stop
    o_stop
}

n_restart()
{
    n_stop
    n_start
}

n_status()
{
    c_status
    a_status
    o_status
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
    echo "  $1 status              Status of $1 servise"
}


#------------------------------------------------------------
# Main part
#------------------------------------------------------------
service=$1
action=$2
options=$3

case $service in
    "collector") case $action in
            "start") c_start "$options";;
            "stop") c_stop;;
            "restart") c_restart "$options";;
            "status") c_status;;
            *)  print_help $service;;
        esac
    ;;
    "profiler") case $action in
            "start") p_start "$options";;
            "stop") p_stop;;
            "restart") p_restart "$options";;
            "status") p_status;;
            *)  print_help $service;;
        esac
    ;;
    "detector") case $action in
            "start") d_start "$options";;
            "stop") d_stop;;
            "restart") d_restart "$options";;
            "status") d_status;;
            *)  print_help $service;;
        esac
    ;;
    "observer") case $action in
            "start") o_start "$options";;
            "stop") o_stop;;
            "restart") o_restart "$options";;
            "status") o_status;;
            *)  print_help $service;;
        esac
    ;;
    "anomaly") case $action in
            "start") a_start "$options";;
            "stop") a_stop;;
            "restart") a_restart "$options";;
            "status") a_status;;
            *)  print_help $service;;
        esac
    ;;
    "ngnetms") case $action in
            "start") n_start "$options";;
            "stop") n_stop;;
            "restart") n_restart "$options";;
            "status") n_status;;
            *)  print_help $service;;
        esac
    ;;
    "optprf") case $action in
            "start") op_start "$options";;
            "stop") op_stop;;
            "restart") op_restart "$options";;
            *)  print_help $service;;
        esac
    ;;
    *)  echo "Usage:"
        echo "  <collector|profiler|detector|observer|optprf> <start|stop|restart|status> [\"options\"]"
        echo "  <anomaly|ngnetms> <start|stop|restart|status>"
        ;;
esac
