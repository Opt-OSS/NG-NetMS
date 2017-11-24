#!/usr/bin/env sh
set +e
function onexit(){ echo "ERROR: $0: Some  errors"; true ; }
trap onexit ERR
/sbin/su-exec ngnms  \
    /sbin/wait-for.sh -h  ${NGNMS_DB_HOST} -p ${NGNMS_DB_PORT} -t 60 -s -- \
         ${NGNMS_HOME}/bin/ngnetms_db --host ${NGNMS_DB_HOST} --port ${NGNMS_DB_PORT}  \
        --name ${NGNMS_DB} --password=${NGNMS_DB_PASSWORD} --user=${NGNMS_DB_USER}
true