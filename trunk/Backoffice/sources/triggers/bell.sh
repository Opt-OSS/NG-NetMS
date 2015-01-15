#!/bin/sh
# NG-NetMS, a Next Generation Network Managment System
# 
# Copyright (C) 2014 Opt/Net
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
# Script to sound a bell via terminal console.
#
# Parameters if launched from ngnms_collector:
# none 
#


echo CONSOLE  --- BELL!
play -n synth 0.5 sine 523 vol 1.0
