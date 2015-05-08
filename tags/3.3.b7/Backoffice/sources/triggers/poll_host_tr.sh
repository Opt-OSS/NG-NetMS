#!/bin/sh
# NG-NetMS, a Next Generation Network Managment System
# 
# Copyright (C) 2015 Opt/Net
# 
# This file is part of NG-NetMS tool.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Authors: T.Matselyukh, D.Danylchenko, A. Jaropud
#
# Script to poll a host on an event
#
# Parameters:
#  severity priority timestamp origin facility code description
#
#[ -z ${0##/*} ] || mydir=`dirname $PWD/$0`/

origin=$4

echo CONSOLE: --> Polling host $origin ...
logger "LOG: --> Polling host $origin ..."

mydir=`pwd`
echo CONSOLE Mydir --- $mydir
logger "LOG: --> Mydir = $mydir"

echo poll_host.pl -D ngnms -U ngnms -W optoss $origin 
logger "LOG: --> Starting poll_host.pl -D ngnms -U ngnms -W optoss $origin ..."

poll_host.pl -D ngnms -U ngnms -W ngnms $origin 

echo CONSOLE: Exit status: $?
logger "LOG: Exit status: $?"

echo CONSOLE: Exiting poll_host_tr.sh script
logger "LOG: Exiting poll_host_tr.sh script"
