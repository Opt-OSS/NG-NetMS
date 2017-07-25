#!/usr/bin/env bash
# Manual run master container, don't run it if docker-compose used
docker  run  -d --name ngnms-core  --env-file  env.list \
    -v //c/VLZ/oDesk/taras/NG/NG-NetMS/Backoffice/NGREADY/Shared://home/ngnms/NGREADY/Shared:rw \
	--link ngnms-psql \
	vladzaitsev/ngnms-core:3.5b2