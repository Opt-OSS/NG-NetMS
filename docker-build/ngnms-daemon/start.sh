#!/usr/bin/env sh
/sbin/wait-for.sh  -t 60 ${NGNMS_DB_HOST}:${NGNMS_DB_PORT} -- \
 exec /sbin/su-exec ngnms ${NGNMS_HOME}/bin/ngnetms_db --host ${NGNMS_DB_HOST} --port ${NGNMS_DB_PORT}  \
  --name ${NGNMS_DB} --password=${NGNMS_DB_PASSWORD} --user=${NGNMS_DB_USER}
