#!/usr/bin/env bash
docker run --name=ngnms-psql \
   -v //c/VLZ/oDesk/taras/NG/NG-NetMS/Database/init-db://docker-entrypoint-initdb.d \
   -p 5432:5432 \
   -e POSTGRES_PASSWORD=optoss \
   -e POSTGRES_USER=ngnms \
   -e POSTGRES_DB=test \
   postgres:9.5.11
