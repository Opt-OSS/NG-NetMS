#!/usr/bin/env bash
docker  run -d --name=ngnms-web-dev  \
    --net="host" \
    --env-file  env.list \
    -v /home/ngnms/Web/www:/var/www:rw \
    -p 80:80 \
    vladzaitsev/ngnms-web