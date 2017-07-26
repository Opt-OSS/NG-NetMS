#!/bin/bash
#
# Create a ngnms database from template or a file
# pg_dump -c -C ngnms > aaa
# comment creation publick sheme
#

DATABASE=$NGNMS_DB
STOP_ON_ERROR=""
QUIET=0
RESET_EV_SEQ=1

[ -z "$NGNMS_HOME" ] && {
    echo Environment variable \$NGNMS_HOME not set.
    exit
}

#DBFILE=$NGNMS_HOME/database/ngnms.sql

function confirm {
    [ "$QUIET" != "1" ] && {
        echo -n "About to delete database '$DATABASE' on host $DB_HOST. Proceed? (Y/n) [n] "
        read i
        [ "$i" == "Y" ] || {
        echo "Very good... Aborted."
        exit
        }
    }

}
function confirm_red {
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    printf  "${RED}LAST WARNING!!
          DO YOU REALLY REALLY WANT TO INITIATE DB?
          ALL SETTINGS AND NETWORK DATA WILL BE LOST
          ALL ROUTER CONFIGS WILL BE DELETED.!!
          ----------------------------------
          OPERATION COULD NOT BE REVERTED!!
          --------------------------------
    ${NC}
"
    confirm

}
function usage {

ME=`basename "$0"`
echo "
drop and recreate $DATABASE database with SQL commands in FILENAME
remove saved routers config in $NGNMS_DATA/rtconfig/

Usage:
   ${ME}   [OPTIONS]... FILENAME

General options:
  -f, --force              force execution, no confirmation dialog
  -s, --stop-on-error      Stop on error while executing FILENAME script
  -r, --reset-events-sequence
                           reset events sequence current value: manual load of old archives will be impossible
                           use if installing new database
  --help                   show this help, then exit

Database connection options:
  -w, --no-password        never prompt for password
  -L, --dbhost=HOSTNAME      database server host or socket directory (default: $NGNMS_DB_HOST)
  -P, --dbport=PORT          database server port (default: $NGNMS_DB_PORT)
  -U, --dbuser=USERNAME  database user name (default: $NGNMS_DB_USER)

Database Input and output options:
  -a, --echo-all           echo all input from script
  -b, --echo-errors        echo failed commands
  -e, --echo-queries       echo commands sent to server
  -E, --echo-hidden        display queries that internal commands generate
  -l, --log-file=FILENAME  send session log to file
  -n, --no-readline        disable enhanced command line editing (readline)
  -o, --output=FILENAME    send query results to file (or |pipe)
  -q, --quiet              run quietly (no messages, only query output)
"
echo
echo
exit
}
DB_IO_OPTION=""
DB_PASS_MODE="--password" #force Dayabase password prompt (should happen automatically)
DB_PORT=${NGNMS_DB_PORT}
DB_USER=$NGNMS_DB_USER
DB_HOST=$NGNMS_DB_HOST

[[ $# -eq 0 ]]&&{
   usage
}
# As long as there is at least one more argument, keep looping
while [[ $# -gt 1 ]]; do
    key="$1"
    case "$key" in
        # This is a flag type option. Will catch either -f or --foo
        --help)                     usage                                                ;;
        -f|--force)                 QUIET=1                                              ;;
        -r|--reset-events-sequence) RESET_EV_SEQ=0                                       ;;
#        -w|--no-password)           DB_PASS_MODE="--no-password"                         ;;
        -a|--echo-all)              DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -b|--echo-errors)           DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -e|--echo-queries)          DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -E|--echo-hidden)           DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -n|--no-readline)           DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -q|--quiet)                 DB_IO_OPTION="$DB_IO_OPTION $key"                    ;;
        -s|--stop-on-error)         DB_IO_OPTION="$DB_IO_OPTION --set ON_ERROR_STOP=on"  ;;
        -l|--log-fil)        shift; DB_IO_OPTION="$DB_IO_OPTION --log-file==$1"          ;;
        -l=*|--log-file=*)          DB_IO_OPTION="$DB_IO_OPTION --log-file==$1"          ;;
        -o|--output)         shift; DB_IO_OPTION="$DB_IO_OPTION --output=$1";            ;;
        -o=*|--output=*)            DB_IO_OPTION="$DB_IO_OPTION --output=$1"             ;;
        #-----------------------------------
        -P|--dbport)         shift; DB_PORT=$1                                           ;;
        -P=*|--dbport=*)            DB_PORT="${key#*=}"                                  ;;
        -U|--dbuser)         shift; DB_USER=$1                                           ;;
        -U=*|--dbuser=*)            DB_USER="${key#*=}"                                  ;;
        -L|--dbhost)         shift; DB_HOST=$1                                           ;;
        -L=*|--dbhost=*)            DB_HOST="${key#*=}"                                  ;;
        #-----------------------------------
        *)
            if [[ $key == -* ]];
            then
                echo
                echo "Unknown option $key"
                echo
                usage
            fi
            ;;
    esac
    shift
    # Shift after checking all the cases to get the next option
done

#last argument is file
DBFILE=$1
if [[ $DBFILE == -* ]];then usage; fi;



[ -z $DBFILE ] && {
    echo "File $DBFILE Not found!"
    echo
    echo
	usage

}
[ -r $DBFILE ] || {
    echo "Can not find database file $DBFILE."
    echo "Aborting."
    usage
}



echo -e "(Re)creating database $DATABASE from file $DBFILE\n"
confirm
confirm_red


echo -n "Database Password for user $DB_USER :"
read -s DB_PASS
echo -e "\ntring to connect to database\n"
T=`PGPASSWORD=$DB_PASS psql -h 127.0.0.1 template1 -c "select now();"`

if [[ $? -ne 0 ]] ; then
    echo -e "\n\nERROR: Could not connect to database!!!\n"
    exit 1
fi


[ "$RESET_EV_SEQ" == "0" ] && {
    echo -e "Saving  events sequence current value from Database\n\n"
	EV_SEQ=`PGPASSWORD=$DB_PASS psql  --username=$DB_USER --port=$DB_PORT --host=$DB_HOST -t -c "SELECT pg_catalog.nextval('events_event_id_seq')"`
} || {
    EV_SEQ=1000;
}



echo -e "Stopping services, this requires sudo password:"
sudo killall ngnetms_collector
sudo killall ngnetms_detector
sudo killall ngnetms_observer
sudo killall ngnetms_profiler


echo -e "Disconnect users from database  '$DATABASE'...\n"
drop=`PGPASSWORD=$DB_PASS   psql --username=$DB_USER --port=$DB_PORT --host=$DB_HOST  $STOP_ON_ERROR template1 -c "select pg_terminate_backend(pid) from pg_stat_activity where datname='$DATABASE'"`
sleep 3;
echo -e "Dropping database '$DATABASE'... \n "
drop=`PGPASSWORD=$DB_PASS  psql  --username=$DB_USER --port=$DB_PORT --host=$DB_HOST template1 -c "drop database if exists $DATABASE" `


echo -e  "Creating new database  '$DATABASE'... \n "
cmd="PGPASSWORD=$DB_PASS  psql   --username=$DB_USER --port=$DB_PORT --host=$DB_HOST $DB_IO_OPTION  template1  < $DBFILE";
eval $cmd;

[ "$RESET_EV_SEQ" == "0" ] && {
    echo  -e "Restoring events sequence current value \n"
	eval "PGPASSWORD=$DB_PASS  psql  --username=$DB_USER --port=$DB_PORT --host=$DB_HOST  -t -c \"SELECT pg_catalog.setval('events_event_id_seq',$EV_SEQ,true)\""
}

echo -e "Clearing ${NGNMS_DATA}/rtconfig/ \n"
`rm -rf  ${NGNMS_DATA}/rtconfig/*`

echo "Done."
printf "
\033[0;32m
Run migrate.pl to upgrade DB to latest release.
\033[0m
"

echo
echo
