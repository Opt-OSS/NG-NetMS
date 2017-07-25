## LF Only!!! Last empty line required
## ssh key prompt
prompt ssh_key
	match /[Ee]nter passphrase for key.+: $/

prompt generic
    match /[\/a-zA-Z0-9._\@-]+ ?(?:\(config[^)]*\))? ?[#>\%] ?$/

macro getVersion
	send show version

macro getHardware
	send show chassis hardware

macro getPhysicalInterfaces
	send show interfaces extensive

macro getConfig
	send show configuration

#EOF

