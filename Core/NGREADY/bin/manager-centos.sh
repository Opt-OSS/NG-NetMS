#!/bin/sh
echo -e
#DEBUG='echo -e'

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
# Default options
#------------------------------------------------------------
VERBOSE="-v 3"
#MQ_SIZE=250
MQ_SIZE=500

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
K=100
N=50
F=25


#------------------------------------------------------------
# Service options
#------------------------------------------------------------

COLLECTOR_UDP_OPTIONS="-s syslog-udp -p 514 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-log.txt -l $LOG_DIR/syslog_collector.log"
COLLECTOR_SNMP_OPTIONS="-s snmp-polling -c $BIN_DIR/db.cfg -f /var/log/snmptraps.log -r $NGNMS_HOME/rules/rules-snmp.txt -l $LOG_DIR/snmp_collector.log"
COLLECTOR_NFLOW_OPTIONS="-s netflow-udp -p 2055 -c $BIN_DIR/db.cfg -r $NGNMS_HOME/rules/rules-netflow.txt -l $LOG_DIR/netflow_collector.log"

PROFILER_OPTIONS="-a 9 $VERBOSE -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log"
DETECTOR_OPTIONS="-N $N -F $F -m $m -d $D $VERBOSE -i mq -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log"

OBSERVER_OPTIONS="$VERBOSE -m -c $BIN_DIR/options.json -o $BIN_DIR/db.cfg -l $LOG_DIR/observer.log"
OPTION_PROFILER="$VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/optprf.log" 

EXTRACTOR_OPTIONS="$VERBOSE -L -o $BIN_DIR/db.cfg -l $LOG_DIR/feature_extractor.log"
PREPROCESSOR_OPTIONS="$VERBOSE -D -o $BIN_DIR/db.cfg -l $LOG_DIR/feature_preprocessor.log"
CLUSTERER_OPTIONS="-D -j $VERBOSE -k $K -o $BIN_DIR/db.cfg -l $LOG_DIR/clusterer.log"
CLASSIFIER_OPTIONS="$VERBOSE -D -o $BIN_DIR/db.cfg -l $LOG_DIR/classifier.log"



#------------------------------------------------------------
# Options Profiler functions
#------------------------------------------------------------
op_initdb()
{
    op_stop
    $DEBUG $BIN_DIR/ngnetms_opt_prf -d $OPTION_PROFILER &
    sleep 1
    echo -e "\n Init Profiler DB tables"
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
    echo -e "\n Starting collectors..."
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_UDP_OPTIONS &
    sleep 3
    echo -e "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_SNMP_OPTIONS  &
    sleep 3
    echo -e "\n"
    $DEBUG sudo -E $BIN_DIR/ngnetms_collector $COLLECTOR_NFLOW_OPTIONS &
    sleep 3
    echo -e "\n Collectors started"
}

c_stop()
{
    $DEBUG sudo killall ngnetms_collector
    sleep 1
    echo -e "\n ngnetms collectors stopped"
}

c_restart()
{
    c_stop
    sleep 2
    c_start "$1"
    echo -e "\n ngnetms collectors restarted"
}

c_status()
{
    echo -e "\tCollector:"
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
    echo -e "\n Init Profiler DB tables"
}

p_start()
{
    [ -z "$1" ] || {
        PROFILER_OPTIONS=$1
    }
    echo -e "\n Starting profiler..."
    $DEBUG sudo $BIN_DIR/ngnetms_profiler $PROFILER_OPTIONS &
    sleep 2
    echo -e "\n started"
}

p_stop()
{
    $DEBUG sudo killall ngnetms_profiler
    sleep 1
    echo -e "\n ngnetms profiler stopped"
}

p_restart()
{
    p_stop
	RESTART_OPTIONS="-j $1"
    p_start $RESTART_OPTIONS
#    p_start "$1"
}

p_status()
{
	echo -e "\tProfiler:"
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
    echo -e "\n Init Detector DB tables"
}

d_start()
{
    [ -z "$1" ] || {
        DETECTOR_OPTIONS=$1
    }

    echo -e "\n Starting detector..."
    $DEBUG sudo $BIN_DIR/ngnetms_detector $DETECTOR_OPTIONS &
    sleep 1
    echo -e "\n started"
}

d_stop()
{
    $DEBUG sudo killall ngnetms_detector
    sleep 1
    echo -e "\n ngnetms detector stopped"
}

d_restart()
{
    d_stop
	RESTART_OPTIONS="-j $1"
    d_start $RESTART_OPTIONS
}

d_status()
{
	echo -e "\tDetector:"
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
    echo -e "\n Init Observer DB tables"
    
    $DEBUG $BIN_DIR/ngnetms_opt_prf -d $OPTION_PROFILER &
    sleep 1
    echo -e "\n Init Profiler DB tables"
}

o_start()
{
    [ -z "$1" ] || {
        OBSERVER_OPTIONS=$1
    }

    echo -e "\n Starting observer"
    $DEBUG sudo $BIN_DIR/ngnetms_observer $OBSERVER_OPTIONS &
    sleep 1
    echo -e "\n started"

    sleep 1
    
    echo -e "\n Starting options profiler..."
    $DEBUG $BIN_DIR/ngnetms_opt_prf $OPTION_PROFILER &
    sleep 1 
    echo -e "\n started"
}

o_stop()
{
    $DEBUG sudo killall ngnetms_observer
    sleep 1
    echo -e "\n ngnetms observer stopped"

    $DEBUG sudo killall ngnetms_opt_prf
    sleep 1
    echo -e "\n options profiler stopped"
}

o_restart()
{
    o_stop
    o_start "$1"
}

o_status()
{
    echo -e "\tObserver:"
    $DEBUG ps -ax | grep /[n/]gnetms_observer >&2
    echo -e "\tOptions profiler:"
    $DEBUG ps -ax | grep /[n/]gnetms_opt_prf >&2
}


#------------------------------------------------------------
# Feature extractor functions
#------------------------------------------------------------
fe_initdb()
{
    fe_stop
    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor -D $EXTRACTOR_OPTIONS &
    sleep 1
    echo -e "\n Init Feature Extractor DB tables"
}

fe_start()
{
    [ -z "$1" ] || {
        EXTRACTOR_OPTIONS=$1
    }

    echo -e "\n Start feature extractor"
    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor $EXTRACTOR_OPTIONS &
}

fe_stop()
{
    $DEBUG sudo killall ngnetms_feature_extractor
    sleep 1
    echo -e "\n ngnetms feature extractor stopped"
}

fe_restart()
{
    fe_stop
    fe_start "$1"
}

fe_status()
{
	echo -e "\tFeature extractor:"
    $DEBUG ps -ax | grep /[n/]gnetms_feature_extractor >&2
}

#------------------------------------------------------------
# Feature preprocessor functions
#------------------------------------------------------------
fp_initdb()
{
    fp_stop
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor $PREPROCESSOR_OPTIONS &
    sleep 2
    echo -e "\n Init Feature Preprocessor DB tables"
}

fp_start()
{
    [ -z "$1" ] || {
        PREPROCESSOR_OPTIONS=$1
    }

    echo -e "\n Starting feature preprocessor"
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor $PREPROCESSOR_OPTIONS &
    sleep 1
    echo -e "\n started"
}

fp_stop()
{
    $DEBUG sudo killall ngnetms_feature_preprocessor
    sleep 1
    echo -e "\n ngnetms feature preprocessor stopped"
}

fp_restart()
{
    fp_stop
    fp_start "$1"
}

fp_status()
{
	echo -e "\tFeature preprocessor:"
    $DEBUG ps -ax | grep /[n/]gnetms_feature_preprocessor >&2
}

#------------------------------------------------------------
# Clusterer functions
# This should be started only after feature_extractor 
# Let Feature extractor finish before starting Clusterer
#------------------------------------------------------------
cu_initdb()
{
    cu_stop
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer $CLUSTERER_OPTIONS &
    sleep 1
    echo -e "\n Init Clusterer DB tables"
}

cu_start()
{
    [ -z "$1" ] || {
        CLUSTERER_OPTIONS=$1
    }

    echo -e "\n Starting Clusterer"
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer $CLUSTERER_OPTIONS &
    sleep 1
    echo -e "\n started"
}

cu_stop()
{
    $DEBUG sudo killall ngnetms_clusterer
    sleep 1
    echo -e "\n ngnetms clusterer stopped"
}

cu_restart()
{
    cu_stop
    cu_start "$1"
}

cu_status()
{
	echo -e "\tClusterer:"
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
    echo -e "\n Init Classifier DB tables"
}

ca_start()
{
    [ -z "$1" ] || {
        CLASSIFIER_OPTIONS=$1
    }

    echo -e "\n Starting Classifier"
    $DEBUG sudo $BIN_DIR/ngnetms_classifier $CLASSIFIER_OPTIONS &
    sleep 1
    echo -e "\n started"
}

ca_stop()
{
    $DEBUG sudo killall ngnetms_classifier
    sleep 1
    echo -e "\n ngnetms classifier stopped"
}

ca_restart()
{
    ca_stop
    ca_start "$1"
}

ca_status()
{
	echo -e "\tClassifier:"
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
        echo -e "\n MQ_Size updated"
    }

    a_stop     		# stop if running 

    echo -e "\n Initializing detector DB tables..."
    $DEBUG sudo $BIN_DIR/ngnetms_detector -D $DETECTOR_OPTIONS &
      sleep 1
    echo -e "\n Init Detector DB tables complete."
      sleep 1
    $DEBUG sudo $BIN_DIR/ngnetms_profiler -D $PROFILER_OPTIONS &
    echo -e "\n Init Profiler DB tables complete."
    echo -e "\n Profiling prior events and re-detecting alarms based on settings in manager.sh header..."
}

a_start()
{
    mq_size=`cat /proc/sys/fs/mqueue/msg_max`
    [ $mq_size -eq $MQ_SIZE ] || {
        $DEBUG sudo su root -c "echo $MQ_SIZE > /proc/sys/fs/mqueue/msg_max"
        echo -e "\n MQ_Size updated"
    }
    #Detector sould be started 1st
    d_start
      sleep 1
    #Profiler shoul be started 2nd
    p_start
}

a_stop()
{
    p_stop
    d_stop
      sleep 1
    echo -e "\n ngnetms Anomaly processing stopped."
}

a_restart()
{
    a_stop
      sleep 1
    d_restart
      sleep 1
    p_restart
    echo -e "\n ngnetms Anomaly processing restarted from the current time."
}

a_dump()
{
    a_stop
    pg_dump --data-only --table=public.anomaly ngnms > /home/ngnms/NGREADY/data/anomaly.db
    pg_dump --data-only --table=public.anomaly_template ngnms > /home/ngnms/NGREADY/data/anomaly_template.db
    a_start
}

a_restore()
{
    a_stop
    $DEBUG psql --table=public.anomaly -d ngnms < /home/ngnms/NGREADY/data/anomaly.db
    $DEBUG psql --table=public.anomaly_template -d ngnms < /home/ngnms/NGREADY/data/anomaly_template.db
    a_start
}

a_status()
{
    p_status
    d_status
}


#------------------------------------------------------------
# NGNMS (all services) functions
#------------------------------------------------------------

n_initdb()
{
    echo -e "\n Initialising DB for anomaly detection NGNMS services"
    a_initdb
    sleep 2

    echo -e "\n Initialising DB for observer NGNMS services"
    o_initdb
    sleep 1
    op_initdb
    sleep 1

    echo -e "\n Initialising DB for AI feature extraction NGNMS services"
    fe_initdb
    sleep 3

# In order to initialize other AI services do this one by one individually.

## now stop everything if still running	
     n_stop
}

n_start()
{
    echo -e "\n Starting base ngnms services"
    c_start
   sleep 1 
    a_start
   sleep 1 
    o_start
   sleep 1 
#    op_start
   sleep 1 
   fe_start

## dont start other AI functions. That needs to wait in order to have some data to train on.
## Feature pre-processor will work better with many anomalies. Usually, good to start just before clusterer.
    echo -e "\n NGNMS Started."
}

n_stop()
{
    echo -e "\n Stopping All ngnms services"
    c_stop
    a_stop
    o_stop
#    op_stop
	fe_stop
	fp_stop
	cu_stop
	ca_stop
    echo -e "\n Done."
}

n_restart()
{
    n_stop
    sleep 2
    n_start
}

n_status()
{
	echo -e ""
    c_status
    a_status
    o_status
#    op_status
	fe_status
	fp_status
	cu_status
	ca_status
	echo -e ""
}


#------------------------------------------------------------
# Help function
#------------------------------------------------------------
print_help()
{
    echo -e "Usage:"
    echo -e "  $1 start [\"options\"]   Start $1 servise"
    echo -e "  $1 stop                Stop $1 servise"
    echo -e "  $1 restart [\"options\"] Restart $1 servise"
    echo -e "  $1 initdb [\"options\"] Init DB tables for $1 servise"
    echo -e "  $1 status              Status of $1 servise"
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
    *)  echo -e "Usage:"
        echo -e "  <collectors|profiler|detector|observer|feature_extractor|feature_preprocessor|clusterer|classifier|optprf> <start|stop|restart|initdb|status> [\"options\"]"
        echo -e "  <anomaly|ngnetms> <start|stop|restart|initdb|status>"
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

else echo -e "\n Enter your password now in order to proceed"     
    if sudo echo -e "Thank you!"
    then
        do_case
    else
       echo -e "\t Unable to proceed... terminating the script"
       exit 1
    fi
fi
