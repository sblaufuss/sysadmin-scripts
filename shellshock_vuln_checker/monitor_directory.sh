#!/bin/bash
# Script to monitor the /race_nas/bash_logs directory for new input
#
# 8 Oct 2014 Shane Blaufuss, CISSP
#
# The goal of this script is to scan a directory that has been configured as the reporting
# location for logcheck.sh to use when it finds attempts to exploit Shellshock.
# This script will alert me when it finds files in that directory.

set -x

LOG_DIRECTORY="/race_nas/bash_logs"
FIND="/bin/find" 
SUBJECT=("Attempted shellshock exploits found, please review the log directory.")
ARGS=$@

function read_args
{
	while getopts "e:hl::" OPT ${ARGS[@]}
	do
		case $OPT in
			l) 
				LOG_DIRECTORY=$OPTARG; echo "Using non-default directory $OPTARG."
				if [ -x $LOG_DIRECTORY ]
				then 
					echo "\$LOG_DIRECTORY changed to $LOG_DIRECTORY."
				else # $LOG DIRECTORY doesn't exist
					echo "$LOG_DIRECTORY doesn't exist, or can't access. Quitting."
					exit 1
				fi
			;;
			h) echo "Usage: $0 -e <email address> [-l <logfile>] "
			;;
			e) EMAIL=$OPTARG
			;;
		esac
	done
}

function scan_dir
{
	MESSAGE=`$FIND $LOG_DIRECTORY -type f -print0`
	README="$LOG_DIRECTORY/README"
	if [[ $MESSAGE = $README ]] ; then MESSAGE=""; fi
	if [[ -z $MESSAGE ]] 
	then 
		exit 0 # If the result of the find command is NULL, nothing was found.
	else
		if [[ -z $EMAIL ]]; then echo "No email found."; exit 1; fi
		echo $MESSAGE | mailx -s "$SUBJECT" $EMAIL
	fi
}

read_args
scan_dir
