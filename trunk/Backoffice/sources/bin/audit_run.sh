#!/bin/sh

mydir=`pwd`
echo CONSOLE Mydir = $mydir

HOST='localhost'
DB='ngnms'
USER='ngnms'
PASSWD='ngnms'

echo perl audit.pl  -d -L $HOST -D $DB -U $USER -W $PASSWD 
/usr/bin/perl /home/ngnms/NGREADY/bin/audit.pl  -d -L $HOST -D $DB -U $USER -W $PASSWD

