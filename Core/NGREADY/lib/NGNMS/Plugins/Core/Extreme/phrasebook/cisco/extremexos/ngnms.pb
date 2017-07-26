## LF Only!!! Last empty line required
## ssh key prompt
prompt ssh_key
	match /[Ee]nter passphrase for key.+: $/

macro disable_paging
    send disable clipaging
macro enable_paging
    send enable clipaging

macro getHardware
	send show version

macro getSoftware
	send show switch

macro getPhysicalInterfaces
	send show ports info detail

macro getLogicalInterfaces
	send show vlan detail



macro getConfig
	send show config

#EOF