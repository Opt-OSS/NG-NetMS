#!/usr/bin/env bash
# update default values of PAM environment variables (used by CRON scripts)
/usr/bin/env | /bin/grep NGNMS | while read -r LINE; do  # read STDIN by line
    # split LINE by "="
    IFS="=" read VAR VAL <<< ${LINE}
    # remove existing definition of environment variable, ignoring exit code
    /bin/sed --in-place "/^${VAR}\=/d"  /etc/environment  || true
    # append new default value of environment variable
    /bin/echo "${VAR}=\"${VAL}\"" >>  /etc/environment.
done
exit 0

