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
# Script to test event triggers and enviroment mapping for current dirs
#
# Parameters if launched from ngnms_collector:
#  severity priority timestamp origin facility code description
#

#[ -z ${0##/*} ] || mydir=`pwd`

mydir=`pwd`
echo CON Mydir --- $mydir
logger "LOGGER Mydir --- $mydir"

echo CON NGNMS_HOME --- $NGNMS_HOME
logger "LOGGER NGNMS_HOME --- $NGNMS_HOME"

origin=$4

echo CON Testing --- $0: testing host $origin
logger "LOGGER Testing ---  $0: testing host $origin"

echo TESTING ******* $1 *** $2 *** $3 *** $origin ***  $5 ***  $6 *** $7 ***
logger "LOGGER TESTING ******* $1 *** $2 *** $3 *** $origin ***  $5 ***  $6 *** $7 ***"
