#!/usr/bin/env bash
docker  run  -d --user=root  --name=ngnms-core  \
    -v /home/ngnms/NGREADY/Shared \
    -v /home/ngnms/NGREADY/data/rtconfig
    --net="host" \
    --env-file  env.list \
    vladzaitsev/ngnms-core:3.5b2