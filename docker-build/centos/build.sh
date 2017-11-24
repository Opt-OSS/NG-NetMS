#!/usr/bin/env bash
DIR=`pwd`
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH
docker build  -t ngnms-base .
cd $DIR
