#!/usr/bin/env bash
docker  run  -d --user=root  --name=ngnms-core  \
    -v /home/ngnms/NGREADY:/home/ngnms/NGREADY:rw \
    -e NGNMS_LOGFILE= \
    -e NGNMS_DEBUG=1 \
    --net="host" \
    --env-file  env.list \
    vladzaitsev/ngnms-core