#!/usr/bin/env bash
docker  run -d --name=ngnms-web  \
    --net="host" \
    --env-file  env.list \
    -p 80:80 \
    vladzaitsev/ngnms-web