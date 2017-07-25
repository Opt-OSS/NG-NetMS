#!/bin/sh

#DEBUG=echo


#------------------------------------------------------------
# Default options
#------------------------------------------------------------
VERBOSE="-v 3"
MQ_SIZE=100

BIN_DIR=/home/ngnms/NGREADY/bin
LOG_DIR=/home/ngnms/NGREADY/logs

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
L=49

#------------------------------------------------------------
# Service options
#------------------------------------------------------------

COLLECTOR_UDP_OPTIONS="-u -p 514 -o $BIN_DIR/db.cfg -r /home/ngnms/NGREADY/rules/rules.txt -l $LOG_DIR/syslog_collector.log"
COLLECTOR_SNMP_OPTIONS="-c snmp -o $BIN_DIR/db.cfg -i /var/log/snmptraps.log -r /home/ngnms/NGREADY/rules/rules.txt -l $LOG_DIR/snmp_collector.log"

PROFILER_OPTIONS="-a 9 $VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log"
DETECTOR_OPTIONS="-L $L -m $m -d $D $VERBOSE -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log"

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
        PROFILER_OPTIONS=$1
    }
    echo "\n Starting profiler..."
    $DEBUG sudo $BIN_DIR/ngnetms_profiler $PROFILER_OPTIONS &
    sleep 2
    echo "\n started"
}

p_stop()
{
    $DEBUG sudo killall ngnetms_profiler
    sleep 1
    echo "\n ngnetms profiler stopped"
}

p_restart()
{
    p_stop
    p_start "$1"
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
    [ -z "$1" ] || {
        DETECTOR_OPTIONS=$1
    }

    echo "\n Starting detector..."
    $DEBUG sudo $BIN_DIR/ngnetms_detector $DETECTOR_OPTIONS &
    sleep 1
    echo "\n started"
}

d_stop()
{
    $DEBUG sudo killall ngnetms_detector
    sleep 1
    echo "\n ngnetms detector stopped"
}

d_restart()
{
    d_stop
    d_start "$1"
}

d_status()
{
	echo "\tDetector:"
    $DEBUG ps -ax | grep /[n/]gnetms_detector >&2
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
# Feature extractor functions
#------------------------------------------------------------
fe_initdb()
{
    fe_stop
    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor -D $EXTRACTOR_OPTIONS &
    sleep 1
    echo "\n Init Feature Extractor DB tables"
}

fe_start()
{
    [ -z "$1" ] || {
        EXTRACTOR_OPTIONS=$1
    }

    echo "\n Start feature extractor"
    $DEBUG sudo $BIN_DIR/ngnetms_feature_extractor $EXTRACTOR_OPTIONS &
}

fe_stop()
{
    $DEBUG sudo killall ngnetms_feature_extractor
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
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor $PREPROCESSOR_OPTIONS &
    sleep 2
    echo "\n Init Feature Preprocessor DB tables"
}

fp_start()
{
    [ -z "$1" ] || {
        PREPROCESSOR_OPTIONS=$1
    }

    echo "\n Starting feature preprocessor"
    $DEBUG sudo $BIN_DIR/ngnetms_feature_preprocessor $PREPROCESSOR_OPTIONS &
    sleep 1
    echo "\n started"
}

fp_stop()
{
    $DEBUG sudo killall ngnetms_feature_preprocessor
    sleep 1
    echo "\n ngnetms feature preprocessor stopped"
}

fp_restart()
{
    fp_stop
    fp_start "$1"
}

fp_status()
{
	echo "\tFeature preprocessor:"
    $DEBUG ps -ax | grep /[n/]gnetms_feature_preprocessor >&2
}

#------------------------------------------------------------
# Clusterer functions
#------------------------------------------------------------
cu_initdb()
{
    cu_stop
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer $CLUSTERER_OPTIONS &
    sleep 1
    echo "\n Init Clusterer DB tables"
}

cu_start()
{
    [ -z "$1" ] || {
        CLUSTERER_OPTIONS=$1
    }

    echo "\n Starting Clusterer"
    $DEBUG sudo $BIN_DIR/ngnetms_clusterer $CLUSTERER_OPTIONS &
    sleep 1
    echo "\n started"
}

cu_stop()
{
    $DEBUG sudo killall ngnetms_clusterer
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
    $DEBUG sudo killall ngnetms_classifier
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
    a_stop
    $DEBUG $BIN_DIR/ngnetms_profiler -D -j $PROFILER_OPTIONS &
    echo "\n Init Profiler DB tables"
    sleep 2

    $DEBUG $BIN_DIR/ngnetms_detector -D -j $DETECTOR_OPTIONS &
    echo "\n Init Detector DB tables"
	a_stop
}

a_start()
{
#    mq_size=`cat /proc/sys/fs/mqueue/msg_max`
#    [ $mq_size -eq $MQ_SIZE ] || {
#        $DEBUG sudo su root -c "echo $MQ_SIZE > /proc/sys/fs/mqueue/msg_max"
#        echo "\n MQ_Size updated"
#    }

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
    sleep 1
    echo "\n ngnetms Anomaly processing stopped"
}

a_restart()
{
    a_stop
	sleep 1
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
# Experimental - work in progress...
    a_stop
    a_dump
    $DEBUG $BIN_DIR/ngnetms_detector -D -j $DETECTOR_OPTIONS &
    sleep 2
    a_restore
    $DEBUG $BIN_DIR/ngnetms_profiler -D -j $PROFILER_OPTIONS &
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
    echo "\n Initialising DB for anomaly detection NGNMS services"
    a_initdb
    sleep 2

#    echo "\n Initialising DB for observer NGNMS services"
#    o_initdb
#    sleep 1
#    op_initdb
#    sleep 1

    echo "\n Initialising DB for AI feature extraction NGNMS services"
    fe_initdb
    sleep 3

# In order to initialize other AI services do this one by one individually.
#	fp_initdb
#    sleep 1
#    cu_initdb
#    sleep 1
#    ca_initdb
#    sleep 1
    ## now stop everything if still running
	
    n_stop
}

n_start()
{
    echo "\n Starting base ngnms services"
    c_start
    a_start
#    o_start
#    op_start
	fe_start
	## dont start other AI functions. That needs to wait in order to have some data to train on.
}

n_stop()
{
    echo "\n Stopping All ngnms services"
    c_stop
    a_stop
    o_stop
    op_stop
	fe_stop
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
	echo ""
    c_status
    a_status
    o_status
    op_status
	fe_status
	fp_status
	cu_status
	ca_status
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
        echo "  <collector|profiler|detector|observer|feature_extractor|feature_preprocessor|clusterer|classifier|optprf> <start|stop|restart|initdb|status> [\"options\"]"
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

else echo "\n Enter your password now in order to proceed"     
    if sudo echo "Thank you!"
    then
        do_case
    else
       echo "\t Unable to proceed... terminating the script"
       exit 1
    fi
fi
