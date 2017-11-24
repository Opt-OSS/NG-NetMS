#-----------------------------------
# default:     match /(?:\[)?\w+@.+(?:\])?\$ $/
# SH single $ prompt
prompt generic
	match /(?:\[)?(?:\w+@.+)?(?:\])?\$\s*$/
prompt privileged
    match /^(?:\[)?root@.+(?:\])?# $/
#-------------------
# -- paging required when linut shows banner
macro paging
	send echo