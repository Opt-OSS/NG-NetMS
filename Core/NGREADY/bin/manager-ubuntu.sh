#!/bin/sh
# ****************************  NGNMS MANAGER SCRIPT ************************************
#
# This script will manage your NGNMS Plus instance. Use wisely, since improper use will
# cause data loss.
#
# Taras Matselyukh   info@opt-net.eu
# Copyright 2017 OPT/NET BV
# ***************************************************************************************

# Error checking -- exit if evaluation is not true
set -o errexit

# Uncomment following line to debug the script
#DEBUG='echo'

#------------------------------------------------------------
# Default options
#------------------------------------------------------------
VERBOSE="-v 1"
MQ_SIZE=1000

#------------------------------------------------------------
# AI & DETECTOR OPTIONS
#------------------------------------------------------------
# m - limit number of anomalies per device discovered
# D - anomaly similarity tolerance in %
# K - number of clusters
# L - anomaly detection threshold level
#------------------------------------------------------------
m=10000
D=10
f=0.05
N=35
F=1

echo "Manager start at: "
date

. /etc/environment
export PATH NGNMS_HOME NGNMS_CONFIGS PERL5LIB MIBDIRS

[ -z "$NGNMS_HOME" ] && {
    echo Environment variable \$NGNMS_HOME not set.
    exit
}

BIN_DIR="$NGNMS_HOME/bin"
LOG_DIR="$NGNMS_HOME/logs"

echo "Home is: $NGNMS_HOME"
echo "BIN Dir is: $BIN_DIR "
echo "LOG Dir is: $LOG_DIR "


#------------------------------------------------------------
# Service options
#------------------------------------------------------------

COLLECTOR_UDP_OPTIONS="-s syslog-udp -p 514 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-log.txt -l $LOG_DIR/syslog_collector.log"
COLLECTOR_SNMP_OPTIONS="-s snmp-polling -c $BIN_DIR/db.cfg -f /var/log/snmptraps.log -r $NGNMS_HOME/rules/rules-snmp.txt -l $LOG_DIR/snmp_collector.log"
COLLECTOR_LOG_OPTIONS="-s syslog-polling -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-log.txt -l $LOG_DIR/syslog_polling_collector.log &"
COLLECTOR_NFLOW_OPTIONS="-s netflow-udp -p 2055 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-netflow.txt -l $LOG_DIR/netflow_collector.log"

PROFILER_OPTIONS="-a 9 $VERBOSE -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log"
DETECTOR_OPTIONS="-N $N -F $F -m $m -d $D $VERBOSE -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log"

OBSERVER_OPTIONS="$VERBOSE -m -c $BIN_DIR/options.json -o $BIN_DIR/db.cfg -l $LOG_DIR/observer.log"
OPTION_PROFILER="$VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/optprf.log" 

EXTRACTOR_OPTIONS="$VERBOSE -L -o $BIN_DIR/db.cfg -l $LOG_DIR/feature_extractor.log"
PREPROCESSOR_OPTIONS="$VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/feature_preprocessor.log"
CLUSTERER_OPTIONS="$VERBOSE -f $f -o $BIN_DIR/db.cfg -l $LOG_DIR/clusterer.log"
CLASSIFIER_OPTIONS="-D $VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/classifier.log"



#------------------------------------------------------------
# Options Profiler functions
#------------------------------------------------------------
op_initdb()
{
    op_stop
    $DEBUG $BIN_DIR/ngnetms_opt_prf -d $OPTION_PROFILER &
    sleep 1
    echo "\n Init Profiler DB tables done."
}

op_start()
{
# Options Profiler to be started last in base group of services

    echo "\n Starting options profiler..."
    $DEBUG $BIN_DIR/ngnetms_opt_prf $OPTION_PROFILER &
    sleep 1 
    echo "\n Done."
}

op_stop()
{
    $DEBUG sudo killall ngnetms_opt_prf || echo " "
    sleep 1
    echo "options profiler is not running now."
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
    sleep 3
    echo "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_SNMP_OPTIONS  &
    sleep 3
    echo "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_NFLOW_OPTIONS &
    sleep 3
    echo "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_LOG_OPTIONS &
    sleep 3
    echo "\n Collectors started"
}

c_stop()
{
    $DEBUG sudo killall ngnetms_collector || true
    sleep 1
    echo "\n ngnetms collectors stopped"
}

c_restart()
{
    c_stop
    sleep 2
    c_start "$1"
    echo "\n ngnetms collectors restarted"
}

c_status()
{
    echo "\tCollector:"
    $DEBUG ps -ax | grep /[n/]gnetms_collector >&2
}


#------------------------------------------------------------
# Profiler functions
#------------------------------------------------------------
p_initdb()
{
    p_stop
    $DEBUG sudo $BIN_DIR/ngnetms_profiler -D $PROFILER_OPTIONS &
    sleep 1
    echo "\n Init Profiler DB tables"
}

p_start()
{
    [ -z "$1" ] || {
        PROFILER_OPTIONS=$*
    }
    echo "\n Starting profiler..."
    $DEBUG sudo $BIN_DIR/ngnetms_profiler $PROFILER_OPTIONS &
    sleep 2
    echo "\n started"
}

p_stop()
{
    $DEBUG sudo killall ngnetms_profiler || true
    sleep 1
    echo "\n ngnetms profiler stopped"
}

p_restart()
{
    p_stop
	RESTART_OPTIONS="-j $PROFILER_OPTIONS $1"
    p_start $RESTART_OPTIONS
}

p_status()
{
	echo "\tProfiler:"
    $DEBUG ps -ax | grep /[n/]gnetms_profiler >&2
}


#------------------------------------------------------------
# Detector functions
#------------------------------------------------------------
d_initdb()
{
    d_stop
    $DEBUG sudo $BIN_DIR/ngnetms_detector -D $DETECTOR_OPTIONS &
    sleep 1
    echo "\n Init Detector DB tables"
}

d_start()
{
    [ -z "$*" ] || {
        DETECTOR_OPTIONS=$*
    }

    echo "\n Starting detector..."
    $DEBUG sudo $BIN_DIR/ngnetms_detector $DETECTOR_OPTIONS &
    sleep 1
    echo "\n started"
}

d_stop()
{
    $DEBUG sudo killall ngnetms_detector || true
    sleep 1
    echo "\n ngnetms detector stopped"
}

d_restart()
{
    d_stop
	RESTART_OPTIONS="-j $DETECTOR_OPTIONS $1"
    d_start $RESTART_OPTIONS
}

d_status()
{
	echo "\tDetector:"
    $DEBUG ps -ax | grep /[n/]gnetms_detector >&2
}

#------------------------------------------------------------
# Observer and Option profiler functions
# Observer and Options Profiler to be started last in base group of services
# Both rely on the presence of the discovered devices. Restart after new devices were discovered
#------------------------------------------------------------
o_initdb()
{
    o_stop
    $DEBUG sudo $BIN_DIR/ngnetms_observer -D $OBSERVER_OPTIONS &
    sleep 1
    echo "\n Init Observer DB tables"
    
    $DEBUG $BIN_DIR/ngnetms_opt_prf -d $OPTION_PROFILER &
    sleep 1
    echo "\n Init Profiler DB tables"
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

    sleep 1
    
    echo "\n Starting options profiler..."
    $DEBUG $BIN_DIR/ngnetms_opt_prf $OPTION_PROFILER &
    sleep 1 
    echo "\n started"
}

o_stop()
{
    $DEBUG sudo killall ngnetms_observer || true
    sleep 1
    echo "\n ngnetms observer stopped"

    $DEBUG sudo killall ngnetms_opt_prf || true
    sleep 1
    echo "\n options profiler stopped"
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
    echo "\tOptions profiler:"
    $DEBUG ps -ax | grep /[n/]gnetms_opt_prf >&2
}


#------------------------------------------------------------
# Feature extractor functions
#------------------------------------------------------------
fe_initdb()
{
    fe_stop
echo "\n WARNING: Function deprecated. Feature extractor functionality is relocated to anomaly detector."
#    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor -D $EXTRACTOR_OPTIONS &
#    sleep 1
#    echo "\n Init Feature Extractor DB tables"
}

fe_start()
{
    [ -z "$1" ] || {
        EXTRACTOR_OPTIONS=$1
    }

echo "\n WARNING: Function deprecated. Feature extractor functionality is relocated to anomaly detector."
#    echo "\n Start feature extractor"
#    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor $EXTRACTOR_OPTIONS &
}

fe_stop()
{
    $DEBUG sudo killall ngnetms_feature_extractor || true
    sleep 1
    echo "\n ngnetms feature extractor stopped"
}

fe_restart()
{
    fe_stop
    fe_start "$1"
}

fe_status()
{
	echo "\tFeature extractor:"
    $DEBUG ps -ax | grep /[n/]gnetms_feature_extractor >&2
}

#------------------------------------------------------------
# Feature preprocessor functions
#------------------------------------------------------------
fp_initdb()
{
    fp_stop
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor -D $PREPROCESSOR_OPTIONS &
    sleep 2
    echo "\n Init Feature Preprocessor DB tables"
}

fp_start()
{
    [ -z "$*" ] || {
        PREPROCESSOR_OPTIONS=$*
    }

    echo "\n Starting feature preprocessor"
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor $PREPROCESSOR_OPTIONS &
    sleep 1
    echo "\n started"
}

fp_stop()
{
    $DEBUG sudo killall ngnetms_feature_preprocessor || true
    sleep 1
    echo "\n ngnetms feature preprocessor stopped"
}

fp_restart()
{
    fp_stop || true
    RESTART_OPTIONS="-j $PREPROCESSOR_OPTIONS $1"
    fp_start $RESTART_OPTIONS
}

fp_status()
{
	echo "\tFeature preprocessor:"
    $DEBUG ps -ax | grep /[n/]gnetms_feature_preprocessor >&2
}

#------------------------------------------------------------------------------
# Clusterer functions:
# These should be started only after feature_extractor and feature preprocessor
# Let Feature extractor finish before starting Clusterer
#------------------------------------------------------------------------------
cu_initdb()
{
    cu_stop
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer -D $CLUSTERER_OPTIONS &
    sleep 1
    echo "\n Init Clusterer DB tables"
}

cu_start()
{
    [ -z "$1" ] || {
        CLUSTERER_OPTIONS=$1
    }

    echo "\n Starting Clusterer"
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer -j $CLUSTERER_OPTIONS &
    sleep 1
    echo "\n started"
}

cu_stop()
{
    $DEBUG sudo killall ngnetms_clusterer || true
    sleep 1
    echo "\n ngnetms clusterer stopped"
}

cu_restart()
{
    cu_stop
    cu_start "$1"
}

cu_status()
{
	echo "\tClusterer:"
    $DEBUG ps -ax | grep /[n/]gnetms_clusterer >&2
}

#------------------------------------------------------------
# Classifier functions
#------------------------------------------------------------

ca_initdb()
{
    ca_stop
    $DEBUG sudo $BIN_DIR/ngnetms_classifier $CLASSIFIER_OPTIONS &
    sleep 1
    echo "\n Init Classifier DB tables"
}

ca_start()
{
    [ -z "$1" ] || {
        CLASSIFIER_OPTIONS=$1
    }

    echo "\n Starting Classifier"
    $DEBUG sudo $BIN_DIR/ngnetms_classifier $CLASSIFIER_OPTIONS &
    sleep 1
    echo "\n started"
}

ca_stop()
{
    $DEBUG sudo killall ngnetms_classifier || true
    sleep 1
    echo "\n ngnetms classifier stopped"
}

ca_restart()
{
    ca_stop
    ca_start "$1"
}

ca_status()
{
	echo "\tClassifier:"
    $DEBUG ps -ax | grep /[n/]gnetms_classifier >&2
}


#------------------------------------------------------------
# Anomaly (profiler & detector) functions
#------------------------------------------------------------
a_initdb()
{
    mq_size=`cat /proc/sys/fs/mqueue/msg_max`
    [ $mq_size -eq $MQ_SIZE ] || {
        $DEBUG sudo su root -c "echo $MQ_SIZE > /proc/sys/fs/mqueue/msg_max"
        echo "\n MQ_Size updated"
    }

    a_stop     		# stop if running 

    echo "\n Initializing detector DB tables..."
    date
    echo "--------------------------------------"
    $DEBUG sudo $BIN_DIR/ngnetms_detector -D $DETECTOR_OPTIONS &
      sleep 1
    echo "\n Init Detector DB tables complete."
      sleep 1
    $DEBUG sudo $BIN_DIR/ngnetms_profiler -D $PROFILER_OPTIONS &
    date
    echo "--------------------------------------"
    echo "\n Init Profiler DB tables complete."
    echo "\n Profiling prior events and re-detecting alarms based on settings in manager.sh header..."
}

a_start()
{
    mq_size=`cat /proc/sys/fs/mqueue/msg_max`
    [ $mq_size -eq $MQ_SIZE ] || {
        $DEBUG sudo su root -c "echo $MQ_SIZE > /proc/sys/fs/mqueue/msg_max"
        echo "\n MQ_Size updated"
    }
    #Detector should be started 1st
    date
    echo "--------------------------------------"
    d_start
      sleep 1
    #Profiler should be started 2nd
    p_start
}

a_stop()
{
    p_stop
    d_stop
      sleep 1
    echo "\n ngnetms Anomaly processing stopped."
}

a_restart()
{
    d_restart
      sleep 1
    p_restart
    echo "\n ngnetms Anomaly processing restarted from the current time."
}

a_dump()
{
    a_stop
    pg_dump --data-only --table=public.anomaly ngnms > /home/ngnms/NGREADY/database/anomaly.db
    pg_dump --data-only --table=public.anomaly_template ngnms > /home/ngnms/NGREADY/database/anomaly_template.db
    a_start
}

a_restore()
{
    a_stop
    $DEBUG psql --table=public.anomaly -d ngnms < /home/ngnms/NGREADY/database/anomaly.db
    $DEBUG psql --table=public.anomaly_template -d ngnms < /home/ngnms/NGREADY/database/anomaly_template.db
    a_start
}

a_status()
{
    p_status || echo " Profiler is not running now."
    d_status || echo " Detector is not running now."
}


#------------------------------------------------------------
# NGNMS (all services) functions
#------------------------------------------------------------

n_initdb()
{
    echo "\n Initialising DB for anomaly detection NGNMS services"
    a_initdb
    sleep 2

    echo "\n Initialising DB for observer NGNMS services"
    o_initdb
    sleep 1
    op_initdb
    sleep 1

    echo "\n Initialising DB for AI feature extraction NGNMS services"
    fe_initdb
    sleep 3

# In order to initialize other AI services do this one by one individually.

## now stop everything if still running if necessary
##     n_stop
}

n_start()
{
    echo "\n Starting base ngnms services"
    c_start
   sleep 1 
    a_start
   sleep 1 
    o_start
   sleep 1 
#    op_start -- moved to o_start
   sleep 1 
#   fe_start  -- deprecated

## dont start other AI functions. This step has to wait in order to have some data to train on.
## Feature pre-processor will work better with many anomalies.
## Best if pre-processor is started and finishes just before clusterer.
    echo "\n NGNMS Started."
}

n_stop()
{
    echo "\n Stopping All ngnms services"
    c_stop
    a_stop
    o_stop
#    op_stop  -- joined with o_stop now
#	fe_stop -- deprecated
	fp_stop
	cu_stop
	ca_stop
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
    c_status || echo " Collectors are not running now."
    a_status || echo " Anomaly detection is not active now."
    o_status || echo " Observer is not running now."
#    op_status || echo "Options Profiler is not running now."  -- joined with Observer now.
#	fe_status || echo "Feature Extractor is not running now."  -- deprecated
	fp_status || echo " Feature pre-processor is not running now."
	cu_status || echo " Clusterer is not running now."
	ca_status || echo " Classifier is not running now."

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
    echo "  $1 initdb [\"options\"]  Init DB tables for $1 servise"
    echo "  $1 status              Status of $1 servise"
}


#------------------------------------------------------------
# Command line case analysis
#------------------------------------------------------------

do_case()
{
case $service in
    "collectors") case $action in
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
            "initdb") o_initdb "$options";;
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
            "initdb") a_initdb;;
            *)  print_help $service;;
        esac
    ;;
	"feature_extractor") case $action in
            "start") fe_start "$options";;
            "stop") fe_stop;;
            "restart") fe_restart "$options";;
            "status") fe_status;;
            "initdb") fe_initdb;;
            *)  print_help $service;;
        esac
    ;;
	"feature_preprocessor") case $action in
            "start") fp_start "$options";;
            "stop") fp_stop;;
            "restart") fp_restart "$options";;
            "status") fp_status;;
            "initdb") fp_initdb;;
            *)  print_help $service;;
        esac
    ;;
	"clusterer") case $action in
            "start") cu_start "$options";;
            "stop") cu_stop;;
            "restart") cu_restart "$options";;
            "status") cu_status;;
            "initdb") cu_initdb;;
            *)  print_help $service;;
        esac
    ;;
	"classifier") case $action in
            "start") ca_start "$options";;
            "stop") ca_stop;;
            "restart") ca_restart "$options";;
            "initdb") ca_initdb;;
            "status") ca_status;;
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
        echo "  <collectors|profiler|detector|observer|feature_extractor|feature_preprocessor|clusterer|classifier|optprf> <start|stop|restart|initdb|status> [\"options\"]"
        echo "  <anomaly|ngnetms> <start|stop|restart|initdb|status>"
        ;;
esac

}

#------------------------------------------------------------
# Main part
#------------------------------------------------------------
service=$1
action=$2
options=$3


issudo=$(sudo -n pwd | wc -l)      # this little trick will return 1 if I can sudo. 1 is result of wc counting 1 line of output. If sudo -n fails and needs pasword, the wc will give 0

if [ ${issudo} -gt 0 ] 

then do_case

else echo "\n Enter your password now in order to proceed\n"
    if sudo echo "Thank you!"
    then
        do_case
    else
       echo "\t Unable to proceed... terminating the script"
       exit 1
    fi
fi
