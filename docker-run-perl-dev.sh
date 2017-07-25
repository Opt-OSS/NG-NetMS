#!/usr/bin/env bash
###############################################################################
# Manual run  container in shell with sources mounted to /home/ngnms/NGREADY
# edit src directory. Should be absolute path
###############################################################################
docker  run  -e TERM=vt100 --user=root  -it --name ngnms-perl  --env-file  env.list \
	-v //c/VLZ/oDesk/taras/NG/NG-NetMS/Backoffice/NGREADY://home/ngnms/NGREADY:rw \
	-e NGNMS_LOGFILE= \
	-e NGNMS_DB_HOST=ngnms-psql \
	--link ngnms-psql \
	vladzaitsev/ngnms-core:3.5b2