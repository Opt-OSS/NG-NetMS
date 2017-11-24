#!/usr/bin/env bash
SRC=`pwd`/../
echo "in $SRC"
docker run --rm -it \
     -v /${SRC}:/Build/src -v /${SRC}/../build:/Build/build  \
     -v //var/run/docker.sock:/var/run/docker.sock \
     ngnms-builder bash