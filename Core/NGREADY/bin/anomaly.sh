#!/bin/sh

#DEBUG=echo

BIN_DIR=/home/ngnms/NGREADY/bin
LOG_DIR=/home/ngnms/NGREADY/logs

#### PARAMETERS SECTION #####
algorithm=9
dev=10
level=101
max=100
option="-D"

# Remove host
a_start()
{
    #Detector sould be started 1st
    $DEBUG $BIN_DIR/anomaly_detector $option -L $level -m $max -d $dev -o $BIN_DIR/db.cfg -l $LOG_DIR/detector.log &
    sleep 3
    #Profiler shoul be started 2nd
    $DEBUG $BIN_DIR/ngnetms_profiler $option -a $algorithm -o $BIN_DIR/db.cfg -l $LOG_DIR/profiler.log &
}

a_stop()
{
    $DEBUG sudo killall ngnetms_profiler
    $DEBUG sudo killall anomaly_detector
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
    $DEBUG ps -ax | grep profiler >&2
    $DEBUG ps -ax | grep anomaly >&2
}

case $1 in
    "start") a_start;;
    "stop") a_stop;;
    "status") a_status;;
    "restart") a_restart;;
    "recreate") a_recreate;;
    "dump") a_dump;;
    "restore") a_restore;;
    *) echo "Available commands:"
       echo "    start     Start services"
       echo "    stop      Stop services"
       echo "    status    Status of the services"
       echo "    restart   Restart services"
       echo "    dump      Dump anomaly adn anomaly_templates tables"
       echo "    restore   Restore anomaly adn anomaly_templates tables"
       echo "    recreate  Stop, dump, drop, restore, start"
       ;;
esac
