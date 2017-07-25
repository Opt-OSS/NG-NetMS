## LF Only!!! Last empty line required
## ssh key prompt
prompt ssh_key
	match /[Ee]nter passphrase for key.+: $/

macro getHardware
	send show version

macro getPhysicalInterfaces
	send show interfaces

macro getLogicalInterfaces
	send show ip interface

macro check_privileged
	send show privilege

macro getConfig
	send show running-config

#EOF