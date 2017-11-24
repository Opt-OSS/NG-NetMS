#!/usr/bin/env bash
set +e
function onexit(){ echo "ERROR: $0: Some  errors"; true ; }
trap onexit ERR
/sbin/wait-for.sh -h  ${NGNMS_DB_HOST} -p ${NGNMS_DB_PORT} -t 60 -s -- \
    /sbin/su-exec ngnms ${NGNMS_HOME}/bin/scheduler.sh
true