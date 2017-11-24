#!/usr/bin/env bash
set +e
function onexit(){ echo "ERROR: $0: Some  errors"; true ; }
trap onexit ERR
/sbin/wait-for.sh -h  ${NGNMS_DB_HOST} -p ${NGNMS_DB_PORT} -t 60 -s -- \
  /sbin/su-exec  ngnms ${NGNMS_HOME}/database/migrate.pl  --debug=2 -L ${NGNMS_DB_HOST} -W ${NGNMS_DB_PASSWORD} -P ${NGNMS_DB_PORT} \
  -U ${NGNMS_DB_USER} -D ${NGNMS_DB}  --upgrade=latest
true

