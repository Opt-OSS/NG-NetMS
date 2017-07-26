#!/usr/bin/env bash
env $(cat ${NGNMS_HOME}/env.list | xargs) perl ${NGNMS_HOME}/bin/scheduler.pl