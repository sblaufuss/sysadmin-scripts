#!/bin/bash
# Script to monitor the /race_nas/bash_logs directory for new input
#
# 8 Oct 2014 Shane Blaufuss, CISSP
#
# The goal of this script is to scan a directory that has been configured as the reporting
# location for logcheck.sh to use when it finds attempts to exploit Shellshock.
# This script will alert me when it finds files in that directory.

LOG_DIRECTORY="/race_nas/bash_logs"
FIND=`/bin/find $LOG_DIRECTORY -type f -print0`
SUBJECT="Attempted shellshock exploits found, please review the log directory."

function scan_dir
{
	MESSAGE=$FIND
	if [ -z $MESSAGE ] 
	then 
		exit 0 # If the result of the find command is NULL, nothing was found.
	else
		echo $MESSAGE | mailx -s $SUBJECT $EMAIL
	fi
}

scan_dir
