#!/bin/bash
########################################
# logcheck.sh
# 
# Copies daily sections from system logfiles and stores or emails them
#
# 7 Oct 2014	SMB 	Initial version
########################################

# Setup variables

# Current date, in http log format
# [Ddd Mmm DD hh:mm:ss YYYY]
# We're looking for "[Ddd Mmm DD" only

DATE=`date +'%m.%d.%y'`
#LOGDATE="[`date +'%a %b %d'`"
MAX_LOGS=5 # Keep 5 days' worth
EVIDENCE="{ :;};"
HOSTNAME=`hostname`
FILENAME="$DATE.log"
GREP=/bin/fgrep
OPTS=$@
ARGS=$#

######
# Functions
######

function usage 
{
	echo "Usage: $0 -l <logfile location> -o <output location, or email address>"
	echo
        exit 0
}

function count_files 
{ # Used to count amount of existing files and how many we need to remove in the logrotate function
	EFILES=($(find $OUTPUT -type f -print0 |xargs -0 ls -tr)) # Create an array of filenames, sorted in order of oldest first
# the array we created above. 
	COUNT=${#EFILES[@]}
        DFILES=$((COUNT - MAX_LOGS)) # DFILES is the number of files we need to delete to have 
# $MAX_LOGS amount of files in $OUTPUT. If EFILES has 7 files listed, then DFILES will be 2. This line subtracts $MAX_LOGS from the number of files contained in $EFILES. So, if $MAX_LOGS is 5 and $EFILES has 7 items in it, the result here is 2, and 2 files should be deleted.
# If COUNT is 1, then 1 - 5 is -4, and nothing needs to be deleted. If COUNT is 5, 5-5 = 0 and 1 should be deleted.
	return 0
}

function get_args
{ # Find out how we were invoked
	if [ $ARGS -lt "4" ] # if no arguments provided to the script
	then
		echo
		echo "Usage: $0 -l <logfile location> -o <output location, or email address>"
		exit
	fi
	
	# Parse out command line flags and args

	while getopts "l:o:h" OPT ${OPTS[@]}
	do
		case $OPT in
			l) # -l was detected, put the logfile location in a variable
				LOGFILE=$OPTARG
			;;
			
			o) # -o was detected, put the output location in another variable
				if [[ $OPTARG = *@* ]]  # the argument to -o is an email address
					then
						EMAIL=$OPTARG
					else
						OUTPUT="${OPTARG}/${HOSTNAME}"
				fi
			;;
			h|*) # Help requested
				usage
			;;
		esac
	done
}

function extract_logs
{ # This part will scan the logs looking for BASH exploits, and record them in a file or email
	if [ -z $OUTPUT ] #if the output variable is not set, then email logs
	then
		$GREP -n -H "$EVIDENCE" $LOGFILE |mailx -s "bash exploits found on `hostname`" $EMAIL
	else # $OUTPUT is defined, meaning that an email address was not found so it must be a filename
		if [ ! -x $OUTPUT ] #if the directory doesn't exist, create it
		then
			mkdir -p $OUTPUT
		fi
		rotate_logs
		$GREP -n -H "$EVIDENCE" $LOGFILE >> "$OUTPUT/$FILENAME"
	fi
}

function rotate_logs
{ 
	count_files
	if [ $DFILES -ge 0 ] 
# If the number of files to delete is 0 or more, do this:
	then

# We're going to step through the $EFILES array up to the number of $DFILES, pull a filename from 
# the EFILES array by index number, and then delete that file.
		until [ $DFILES -eq 0 ] # Do this loop until $DFILES is -1 
		do
			for((i=0; i <= $DFILES; i++)) # Step through $DFILES amount of elements
			{	
				rm "${EFILES[$i]}" # use absolute pathname
			DFILES=$((DFILES - 1))
			}
		done
	else
		# Less than max amount of files present; go ahead and write one by returning to extract_logs.
		return 0
	fi
	return 1
}



#######
# Main section
#######

get_args # Figure out what we need to do
extract_logs	# filter for evidence, and either email it or write it to a directory defined in $OUTPUT


