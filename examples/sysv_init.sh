#!/bin/bash
#
# A system-v style init script, that switches on $0 to decide what
# to run.
# 
# You will want to have configdir set to a place where your config
# files are found, named after the init script.  Making a symlink to
# the script named "monkey" would use mongrel_runit and load the
# monkey.yml file.
#

configdir="/etc/mongrel_runit"
basename=`basename $0`
exec mongrel_runit -a $basename -c $configdir/$basename.yml $@
