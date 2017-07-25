## LF Only!!! Last empty line required
prompt user
    match /[Uu]sername: $/

prompt pass
    match /password(?: for \w+)?: $/


prompt generic
#-----------------------------------
# default:     match /(?:\[)?\w+@.+(?:\])?\$ $/
# SH single $ prompt
	match /(?:\[)?(?:\w+@.+)?(?:\])?\$\s*$/
prompt privileged
    match /^(?:\[)?root@.+(?:\])?# $/

macro begin_privileged
    send sudo su -
    match pass or privileged

macro end_privileged
    send exit
    match generic

macro disconnect
    send logout

macro getModel
  	send cat   /etc/*-rel* /etc/*_ver*

macro getHardware
#  	send uname -m
	send lscpu

macro getMemory
#  	send uname -m
	send cat /proc/meminfo

macro getSoftware
  	send uname -r

macro getInterfaceSpeed
  	send PATH=$PATH:/usr/sbin  ethtool %s 2>/dev/null'

macro getInterfaces
	send ip address show
#EOF
