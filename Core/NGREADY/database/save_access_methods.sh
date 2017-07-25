#!/bin/bash

PG_DUMP='/usr/bin/pg_dump'
PSQL='/usr/bin/psql';

DATABASE=ngnms
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
        echo -n "About to delete ALL access methods and device access bindings from Database? (y/n) [n] "
        read i
        [ "$i" == "y" ] || [ "$i" == "Y" ] || {
        echo "Very good... Aborted."
        exit
        }
    }

}
function confirm_red {
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    printf  "${RED}LAST WARNING!!
          DO YOU REALLY REALLY WANT TO DELETE ACEESS METHODS?
          SOME DEVICES COULD BE NOT REACHABLE
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
dump or restore access methods for devices from  $DATABASE

Usage:
   ${ME}  [OPTIONS]...

General options:
  -s|--save                save access methods
  -r|--restore             restore access methods from file
  -f, --file=FILENAME      send/read methods to/form file
                           Required when restoring methods
  --help                   show this help, then exit

Database connection options:
  -w, --no-password        never prompt for password
  -h, --host=HOSTNAME      database server host or socket directory (default: $NGNMS_DB_HOST)
  -p, --port=PORT          database server port (default: $NGNMS_DB_PORT)
  -U, --username=USERNAME  database user name (default: $NGNMS_DB_USER)
"
echo
echo
exit
}
MODE=""
DBFILE=""
DB_PASS_MODE="--password" #force Dayabase password prompt (should happen automatically)
[[ $# -eq 0 ]]&&{
   usage
}
# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # This is a flag type option. Will catch either -f or --foo
        --help)                     usage                       ;;
        -s|--save)                  MODE="save"                 ;;
        -r|--restore)               MODE="restore"              ;;
        -w|--no-password)           DB_PASS_MODE="--no-password";;
        #-----------------------------------
        -f|--file)           shift; DBFILE=$1                   ;;
        -f=*|--file=*)              DBFILE="${key#*=}"          ;;
        -P|--dbport)         shift; DB_PORT=$1                  ;;
        -p=*|--dbport=*)            DB_PORT="${key#*=}"         ;;
        -U|--dbuser)         shift; DB_USER=$1                  ;;
        -U=*|--dbuser=*)            DB_USER="${key#*=}"         ;;
        -L|--dbhost)         shift; DB_HOST=$1                  ;;
        -L=*|--dbhost=*)            B_HOST="${key#*=}"          ;;
        #-----------------------------------
        *)                          usage                       ;;
    esac
    shift
    # Shift after checking all the cases to get the next option
done
if [ $MODE == "" ]; then  usage ; fi
if [ $MODE == "restore" ] && [ ! -f $DBFILE ];then
        echo
        echo "File ${DBFILE} Not found!"
        echo
        usage
fi

CONNECT="--host=${DB_HOST} --port=${DB_PORT} ${DB_PASS_MODE} --username=${DB_USER} --dbname=${DATABASE}";
if [ ! $DBFILE == "" ]; then  DBFILE="--file=${DBFILE}" ; fi


if [ $MODE == "restore" ];then
    confirm
    confirm_red
    echo  "Clearing access methods"
    drop=`echo "truncate access CASCADE; truncate table general_settings; " | ${PSQL}  ${CONNECT}`
    echo  "Restoring methods from ${DBFILE}"
    RESTORE_CMD="${PSQL} ${CONNECT} ${DBFILE} "
    eval $RESTORE_CMD

fi


if [ $MODE == "save" ]; then
    SAVE_CMD="${PG_DUMP} ${CONNECT} --data-only --format=plain --inserts -t general_settings  -t access -t attr_value ${DBFILE} "
    eval $SAVE_CMD
fi







echo
echo
